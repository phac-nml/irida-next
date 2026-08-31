# frozen_string_literal: true

require 'test_helper'

module Groups
  class GroupLinksTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      @namespace = groups(:group_one)
      @group_links_count = namespace_group_links.select { |group_link| group_link.namespace == @namespace }.count
      @group_link5 = namespace_group_links(:namespace_group_link5)
      @group_link14 = namespace_group_links(:namespace_group_link14)
    end

    test 'can create a group to group link' do
      sign_in @user
      group = groups(:group_six)

      get group_members_path(@namespace, tab: 'invited_groups')
      assert_response :success
      assert_select 'button', text: I18n.t(:'groups.members.index.invite_group'), count: 1

      get new_group_group_link_path(@namespace)
      assert_response :success
      assert_select 'p',
                    text: I18n.t(:'groups.group_links.new.sharing_namespace_with_group', name: @namespace.human_name)

      assert_difference -> { @namespace.shared_with_group_links.of_ancestors_and_self.count }, 1 do
        post group_group_links_path(@namespace),
             params: { namespace_group_link: {
               group_id: group.id,
               group_access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('concerns.share_actions.create.success',
                                                                          namespace_name: @namespace.human_name,
                                                                          group_name: group.human_name)}"
          end
        end
      end
    end

    test 'listing group links shows manage buttons for users with permission' do
      sign_in @user

      get group_group_links_path(@namespace, format: :turbo_stream)
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr' do
            # Check for edit buttons (rendered in edit_group_link partial)
            assert_select "button[aria-label*='#{I18n.t('common.actions.edit')}']"
            # Check for unlink/delete buttons
            assert_select 'button', text: I18n.t('groups.group_links.index.unlink'), minimum: 1
          end
        end
      end
    end

    test 'listing group links does not show manage buttons for users without permission' do
      sign_in users(:ryan_doe)

      get group_group_links_path(@namespace, format: :turbo_stream)
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr' do
            assert_select "button[aria-label*='#{I18n.t('common.actions.edit')}']", count: 0
            assert_select 'button', text: I18n.t('groups.group_links.index.unlink'), count: 0
          end
        end
      end
    end

    test 'cannot add a group to group link due to insufficient permissions' do
      sign_in users(:ryan_doe)

      get group_members_path(@namespace, tab: 'invited_groups')
      assert_response :success
      assert_select 'button', text: I18n.t(:'groups.members.index.invite_group'), count: 0

      assert_no_difference -> { @namespace.shared_with_group_links.of_ancestors_and_self.count } do
        post group_group_links_path(@namespace),
             params: { namespace_group_link: {
               group_id: groups(:group_six).id,
               group_access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'can remove a group to group link' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      assert_difference -> { @namespace.shared_with_group_links.of_ancestors_and_self.count }, -1 do
        delete group_group_link_path(@namespace, namespace_group_link), as: :turbo_stream
      end

      ns_name = namespace_group_link.namespace.human_name
      group_name = namespace_group_link.group.human_name

      assert_response :success
      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('concerns.share_actions.destroy.success',
                                                                          namespace_name: ns_name,
                                                                          group_name: group_name)}"
          end
        end
      end
    end

    test 'cannot remove a group to group link which may have been unlinked in another tab' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      namespace_group_link.destroy

      delete group_group_link_path(@namespace, namespace_group_link), as: :turbo_stream

      assert_response :not_found
    end

    test 'cannot remove a group to group link due to insufficient permissions' do
      sign_in users(:ryan_doe)

      assert_no_difference -> { @namespace.shared_with_group_links.count } do
        delete group_group_link_path(@namespace, @group_link5), as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'cannot remove a group to group link if logged in user has role changed to a level which cannot modify' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      member_namespace_ids_to_update = @namespace.shared_with_group_links.pluck(:group_id) +
                                       [namespace_group_link.namespace.id]

      get group_members_path(@namespace, tab: 'invited_groups')
      assert_response :success

      assert_select "turbo-frame#invited_groups[src='#{group_group_links_path(
        @namespace, format: :turbo_stream
      )}'][loading='lazy']"

      get group_group_links_path(@namespace), as: :turbo_stream

      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr td:nth-child(1)', text: namespace_group_link.group.name
        end
      end

      Member.where(user: @user,
                   namespace: member_namespace_ids_to_update).update(access_level: Member::AccessLevel::GUEST)

      assert_no_difference -> { @namespace.shared_with_group_links.count } do
        delete group_group_link_path(@namespace, namespace_group_link), as: :turbo_stream
      end

      assert_response :unauthorized

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t(
                            'common.statuses.error'
                          )}: #{I18n.t(
                            'action_policy.policy.group.unlink_namespace_with_group?',
                            name: namespace_group_link.namespace.human_name
                          )}"
          end
        end
      end
    end

    test 'can update namespace group links group access level to another access level' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      Timecop.travel(Time.zone.now + 5) do
        patch group_group_link_path(@namespace, namespace_group_link),
              params: { namespace_group_link: {
                group_access_level: Member::AccessLevel::ANALYST
              } },
              as: :turbo_stream

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]'
          end
        end

        assert_select 'turbo-stream[action="refresh"]'

        get group_group_links_path(@namespace,
                                   format: :turbo_stream,
                                   group_links_q: { group_name_cont: namespace_group_link.group.name })
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
          assert_select 'template' do
            assert_select "tr#namespace_group_link_#{namespace_group_link.id} td:nth-child(4)",
                          text: I18n.t('activerecord.models.member.access_level.analyst')
          end
        end
      end
    end

    test 'can update namespace group links expiration' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)
      expiry_date = (Time.zone.today + 7).strftime('%Y-%m-%d')

      Timecop.travel(Time.zone.now + 5) do
        patch group_group_link_path(@namespace, namespace_group_link),
              params: { namespace_group_link: {
                expires_at: expiry_date
              } },
              as: :turbo_stream

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]'
          end
        end

        assert_select 'turbo-stream[action="refresh"]'

        get edit_group_group_link_path(@namespace, namespace_group_link, format: :turbo_stream)
        assert_response :success
        assert_select "#namespace_group_link_expires_at-input[value='#{expiry_date}']"
      end
    end

    test 'cannot update namespace group link' do
      sign_in users(:ryan_doe)

      patch group_group_link_path(@namespace, @group_link5),
            params: { namespace_group_link: {
              group_access_level: Member::AccessLevel::ANALYST
            } },
            as: :turbo_stream

      assert_response :unauthorized
    end

    test 'group member of Group C can access Group B as it is shared with Group C' do
      sign_in users(:user25)
      namespace_group_link = namespace_group_links(:namespace_group_link9)

      get group_path(namespace_group_link.namespace)

      assert_response :success
      assert_select 'h1', text: namespace_group_link.namespace.human_name, count: 1
      assert_select 'dd', text: namespace_group_link.namespace.description, count: 1
    end

    test 'group member of Group B can access Group A as it is shared with group B' do
      sign_in users(:user24)
      namespace_group_link = namespace_group_links(:namespace_group_link8)

      get group_path(namespace_group_link.namespace)

      assert_response :success
      assert_select 'h1', text: namespace_group_link.namespace.human_name, count: 1
      assert_select 'dd', text: namespace_group_link.namespace.description, count: 1
    end

    test 'group member of Group B cannot access Group C as it is not shared with Group B' do
      sign_in users(:user24)
      namespace_group_link = namespace_group_links(:namespace_group_link9)

      get group_path(namespace_group_link.group)

      assert_response :unauthorized

      assert_select 'h1', text: I18n.t('application.errors.access_denied')
    end

    test 'group member of Group C cannot see Group A' do
      sign_in users(:user25)
      no_access_namespace_group_link = namespace_group_links(:namespace_group_link8)

      get group_path(no_access_namespace_group_link.namespace)

      assert_response :unauthorized

      assert_select 'h1', text: I18n.t('application.errors.access_denied')
    end

    test 'group member of Group A cannot see Group C' do
      sign_in users(:john_doe)
      no_access_namespace_group_link = namespace_group_links(:namespace_group_link9)

      get group_path(no_access_namespace_group_link.namespace)

      assert_response :unauthorized

      assert_select 'h1', text: I18n.t('application.errors.access_denied')
    end

    test 'group member of Group C cannot access Group B as the access has expired' do
      sign_in users(:user25)
      namespace_group_link = namespace_group_links(:namespace_group_link9)

      namespace_group_link.update_column(:expires_at, Time.zone.today - 1) # rubocop:disable Rails/SkipsModelValidations

      get group_path(namespace_group_link.namespace)

      assert_response :unauthorized

      assert_select 'h1', text: I18n.t('application.errors.access_denied')
    end

    test 'can search group links by group name' do
      sign_in @user

      get group_group_links_path(@namespace, format: :turbo_stream)
      assert_response :success
      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr', count: 2
        end
      end

      get group_group_links_path(@namespace,
                                 format: :turbo_stream,
                                 group_links_q: { group_name_cont: @group_link5.group.name })
      assert_response :success
      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr', count: 1
          assert_select 'table tbody tr td:nth-child(1)', text: @group_link5.group.name
        end
      end
    end

    test 'cannot update namespace group link which may have been deleted in another tab' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      namespace_group_link.destroy

      patch group_group_link_path(@namespace, namespace_group_link),
            params: { namespace_group_link: {
              expires_at: (Time.zone.today + 7).strftime('%Y-%m-%d')
            } },
            as: :turbo_stream

      assert_response :not_found
    end

    test 'should apply default sort and support sorting group links' do
      sign_in @user

      group_link5 = namespace_group_links(:namespace_group_link5)
      group_link14 = namespace_group_links(:namespace_group_link14)

      get group_group_links_path(@namespace, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link5.group.name
      assert_select 'table tbody tr:nth-child(2) td:first-child', text: group_link14.group.name

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'group_name desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link14.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link5.group.name

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'group_access_level asc' })
      assert_response :success
      assert_sort_state(4, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link5.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link14.group.name

      get group_group_links_path(@namespace, format: :turbo_stream, group_links_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link5.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link14.group.name
    end

    test 'should not share group b with group a as group b doesn\'t exist' do
      sign_in @user
      group_id = 1

      post group_group_links_path(@namespace,
                                  params: { namespace_group_link: {
                                    group_id:,
                                    group_access_level: Member::AccessLevel::ANALYST
                                  }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'group b already shared with group a' do
      sign_in @user
      group_six = groups(:group_six)

      assert_difference -> { group_six.shared_with_group_links.count }, 1 do
        post group_group_links_path(group_six,
                                    params: { namespace_group_link: {
                                      group_id: @namespace.id,
                                      group_access_level: Member::AccessLevel::ANALYST
                                    }, format: :turbo_stream })
      end
      assert_response :ok

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('concerns.share_actions.create.success',
                                                                          namespace_name: group_six.human_name,
                                                                          group_name: @namespace.human_name)}"
          end
        end
      end

      assert_no_difference -> { group_six.shared_with_group_links.count } do
        post group_group_links_path(group_six,
                                    params: { namespace_group_link: {
                                      group_id: @namespace.id,
                                      group_access_level: Member::AccessLevel::ANALYST
                                    }, format: :turbo_stream })
      end

      assert_response :unprocessable_content

      assert_select 'turbo-stream[action="append"][target="flashes"]', count: 0
    end

    test 'unshare group when link doesn\'t exist with another group' do
      sign_in @user
      namespace = groups(:group_six)

      assert_no_difference -> { namespace.shared_with_group_links.count } do
        delete group_group_link_path(namespace, 1,
                                     format: :turbo_stream)

        assert_response :not_found
      end
    end

    test 'should not update namespace group share due to invalid params' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link2)

      assert_no_changes -> { namespace_group_link.reload.group_access_level } do
        patch group_group_link_path(namespace_group_link.namespace, namespace_group_link, params: {
                                      namespace_group_link: {
                                        group_access_level: -1
                                      }, format: :turbo_stream
                                    })

        assert_response :unprocessable_content
      end
    end

    test 'destroy renders unprocessable_content when record is not deleted' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      # Mock the deleted? method to return false, simulating a failed delete
      NamespaceGroupLink.any_instance.stubs(:deleted?).returns(false)

      delete group_group_link_path(@namespace, namespace_group_link),
             as: :turbo_stream

      assert_response :unprocessable_content
      # Verify error alert is shown
      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]'
        end
      end
    end

    test 'destroy renders bad_request when namespace group link is nil' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      Groups::GroupLinksController.any_instance.stubs(:namespace_group_link).returns(nil)
      unlink_service = mock('group_unlink_service')
      unlink_service.stubs(:execute).returns(nil)
      GroupLinks::GroupUnlinkService.stubs(:new).returns(unlink_service)

      delete group_group_link_path(@namespace, namespace_group_link),
             as: :turbo_stream

      assert_response :bad_request
      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]'
        end
      end
    end
  end
end
