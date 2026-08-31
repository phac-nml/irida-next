# frozen_string_literal: true

require 'test_helper'

module Projects
  class GroupLinksTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      @namespace = namespaces_project_namespaces(:project25_namespace)
      @project = projects(:project25)
      @group_links_count = namespace_group_links.select { |group_link| group_link.namespace == @namespace }.count
      @group_link2 = namespace_group_links(:namespace_group_link2)
      @group_link5 = namespace_group_links(:namespace_group_link5)
      @group_link14 = namespace_group_links(:namespace_group_link14)
    end

    test 'can create a project to group link' do
      sign_in @user
      group = groups(:subgroup_one_group_three)

      get namespace_project_members_path(@namespace.parent, @project, tab: 'invited_groups')
      assert_response :success
      assert_select 'button', text: I18n.t(:'projects.members.index.invite_group'), count: 1

      get new_namespace_project_group_link_path(@namespace.parent, @project)
      assert_response :success
      assert_select 'p',
                    text: I18n.t(:'projects.group_links.new.sharing_namespace_with_group', name: @namespace.human_name)

      assert_difference -> { @namespace.shared_with_group_links.count }, 1 do
        post namespace_project_group_links_path(@namespace.parent, @project),
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

    test 'listing group links shows manage buttons for user with permission' do
      sign_in @user

      get namespace_project_group_links_path(@namespace.parent, @project, format: :turbo_stream)
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr' do
            assert_select "button[aria-label*='#{I18n.t('common.actions.edit')}']"
            assert_select 'button', text: I18n.t('projects.group_links.index.unlink')
          end
        end
      end
    end

    test 'listing group links does not show manage buttons for user without permission' do
      sign_in users(:ryan_doe)

      get namespace_project_group_links_path(@namespace.parent, @project, format: :turbo_stream)
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr' do
            assert_select "button[aria-label*='#{I18n.t('common.actions.edit')}']", count: 0
            assert_select 'button', text: I18n.t('projects.group_links.index.unlink'), count: 0
          end
        end
      end
    end

    test 'cannot add a project to group link due to insufficient permissions' do
      sign_in users(:ryan_doe)

      get namespace_project_members_path(@namespace.parent, @project, tab: 'invited_groups')
      assert_response :success
      assert_select 'button', text: I18n.t(:'projects.members.index.invite_group'), count: 0

      assert_no_difference -> { @namespace.shared_with_group_links.of_ancestors.count } do
        post namespace_project_group_links_path(@namespace.parent, @project),
             params: { namespace_group_link: {
               group_id: groups(:group_six).id,
               group_access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'can remove a project to group link' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      assert_difference -> { @namespace.shared_with_group_links.count }, -1 do
        delete namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link), as: :turbo_stream
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

    test 'cannot remove a project to group link that may have been unlinked in another tab' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      namespace_group_link.destroy

      delete namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link), as: :turbo_stream

      assert_response :not_found
    end

    test 'cannot remove a project to group link' do
      sign_in users(:ryan_doe)

      delete namespace_project_group_link_path(@namespace.parent, @project,
                                               namespace_group_links(:namespace_group_link3)), as: :turbo_stream

      assert_response :unauthorized
    end

    test 'cannot remove a project to group link if logged in user has role changed to a level which cannot modify' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      member_namespace_ids_to_update = @namespace.shared_with_group_links.of_ancestors.pluck(:group_id) +
                                       namespace_group_link.namespace.parent.self_and_ancestors.ids +
                                       [namespace_group_link.namespace.id]

      Member.where(user: @user,
                   namespace: member_namespace_ids_to_update).update(access_level: Member::AccessLevel::GUEST)

      delete namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link), as: :turbo_stream

      assert_response :unauthorized
    end

    test 'can update namespace group links group access level to another access level' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      Timecop.travel(Time.zone.now + 5) do
        patch namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link),
              params: { namespace_group_link: {
                group_access_level: Member::AccessLevel::GUEST
              } },
              as: :turbo_stream

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]'
          end
        end

        assert_select 'turbo-stream[action="refresh"]'

        get namespace_project_group_links_path(@namespace.parent,
                                               @project,
                                               format: :turbo_stream,
                                               group_links_q: { group_name_cont: namespace_group_link.group.name })
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
          assert_select 'template' do
            assert_select "tr#namespace_group_link_#{namespace_group_link.id} td:nth-child(4)",
                          text: I18n.t('activerecord.models.member.access_level.guest')
          end
        end
      end
    end

    test 'can update namespace group links expiration' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)
      expiry_date = (Time.zone.today + 7).strftime('%Y-%m-%d')

      Timecop.travel(Time.zone.now + 5) do
        patch namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link),
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

        get edit_namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link,
                                                   format: :turbo_stream)
        assert_response :success
        assert_select "#namespace_group_link_expires_at-input[value='#{expiry_date}']"
      end
    end

    test 'cannot update namespace group links' do
      sign_in users(:ryan_doe)

      patch namespace_project_group_link_path(
        @namespace.parent, @project, namespace_group_links(:namespace_group_link3)
      ),
            params: { namespace_group_link: {
              group_access_level: Member::AccessLevel::GUEST
            } },
            as: :turbo_stream

      assert_response :unauthorized
    end

    test 'group member of Group B can access Group A projects as it is shared with Group A' do
      sign_in users(:user24)
      namespace_group_link = namespace_group_links(:namespace_group_link10)

      get namespace_project_path(namespace_group_link.namespace.parent, namespace_group_link.namespace.project)

      assert_response :success
      assert_select 'h1', text: namespace_group_link.namespace.name, count: 1
      assert_select 'dd', text: namespace_group_link.namespace.description, count: 1
    end

    test 'group member of Group B cannot access Group C projects as it is not shared with Group B' do
      sign_in users(:user24)
      namespace_group_link = namespace_group_links(:namespace_group_link11)

      get namespace_project_path(namespace_group_link.namespace.parent, namespace_group_link.namespace.project)

      assert_response :unauthorized
    end

    test 'group member of Group C cannot see Group A projects' do
      sign_in users(:user25)
      no_access_namespace_group_link = namespace_group_links(:namespace_group_link10)

      get namespace_project_path(no_access_namespace_group_link.namespace.parent,
                                 no_access_namespace_group_link.namespace.project)

      assert_response :unauthorized
    end

    test 'group member of Group A cannot see Group C projects' do
      sign_in @user
      no_access_namespace_group_link = namespace_group_links(:namespace_group_link11)

      get namespace_project_path(no_access_namespace_group_link.namespace.parent,
                                 no_access_namespace_group_link.namespace.project)

      assert_response :unauthorized
    end

    test 'group member of Group B cannot access Group A projects as the access has expired' do
      sign_in users(:user24)
      namespace_group_link = namespace_group_links(:namespace_group_link10)

      NamespaceGroupLink.where(namespace: [namespace_group_link.namespace, namespace_group_link.namespace.parent],
                               group: namespace_group_link.group)
                        .update_all(expires_at: Time.zone.today - 1) # rubocop:disable Rails/SkipsModelValidations

      get namespace_project_path(namespace_group_link.namespace.parent, namespace_group_link.namespace.project)

      assert_response :unauthorized
    end

    test 'can search group links by group name' do
      sign_in @user

      get namespace_project_group_links_path(@namespace.parent, @project, format: :turbo_stream)
      assert_response :success
      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr', count: 4
        end
      end

      get namespace_project_group_links_path(@namespace.parent,
                                             @project,
                                             format: :turbo_stream,
                                             group_links_q: { group_name_cont: @group_link2.group.name })
      assert_response :success
      assert_select 'turbo-stream[action="update"][target="invited_groups"]' do
        assert_select 'template' do
          assert_select 'table tbody tr', count: 1
          assert_select 'table tbody tr td:nth-child(1)', text: @group_link2.group.name
        end
      end
    end

    test 'cannot update namespace group link which may have been deleted in another tab' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      namespace_group_link.destroy

      patch namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link),
            params: { namespace_group_link: {
              expires_at: (Time.zone.today + 7).strftime('%Y-%m-%d')
            } },
            as: :turbo_stream

      assert_response :not_found
    end

    test 'should apply default sort and support sorting project group links' do
      sign_in @user

      project_namespace = namespaces_project_namespaces(:project25_namespace)
      project = projects(:project25)

      group_link2 = namespace_group_links(:namespace_group_link2)
      group_link5 = namespace_group_links(:namespace_group_link5)
      group_link14 = namespace_group_links(:namespace_group_link14)

      get namespace_project_group_links_path(project_namespace.parent, project, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link2.group.name
      assert_select 'table tbody tr:nth-child(2) td:first-child', text: group_link5.group.name

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'group_name desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link14.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link2.group.name

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'group_access_level asc' })
      assert_response :success
      assert_sort_state(4, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link5.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link14.group.name

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_select 'table tbody tr:first-child td:first-child', text: group_link2.group.name
      assert_select 'table tbody tr:last-child td:first-child', text: group_link14.group.name
    end

    test 'should not share project with group as group doesn\'t exist' do
      sign_in @user
      group_id = 1
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id:,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'project namespace already shared with group' do
      sign_in @user
      group = groups(:group_one)
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :ok

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'unshare project when link doesn\'t exist' do
      sign_in @user
      project_namespace = namespaces_project_namespaces(:project23_namespace)

      delete namespace_project_group_link_path(project_namespace.parent,
                                               project_namespace.project,
                                               1,
                                               format: :turbo_stream)

      assert_response :not_found
    end

    test 'should not update namespace group share due to invalid params' do
      sign_in @user
      namespace_group_link_one = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link_one.namespace

      patch namespace_project_group_link_path(project_namespace.parent,
                                              project_namespace.project,
                                              namespace_group_link_one,
                                              params: {
                                                namespace_group_link: {
                                                  group_access_level: -1
                                                }, format: :turbo_stream
                                              })

      assert_response :unprocessable_content
    end

    test 'destroy renders unprocessable_content when record is not deleted' do
      sign_in @user
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      # Mock the deleted? method to return false, simulating a failed delete
      NamespaceGroupLink.any_instance.stubs(:deleted?).returns(false)

      delete namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link),
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
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      Projects::GroupLinksController.any_instance.stubs(:namespace_group_link).returns(nil)
      unlink_service = mock('group_unlink_service')
      unlink_service.stubs(:execute).returns(nil)
      GroupLinks::GroupUnlinkService.stubs(:new).returns(unlink_service)

      delete namespace_project_group_link_path(@namespace.parent, @project, namespace_group_link),
             as: :turbo_stream

      assert_response :bad_request
      # Verify error alert is shown
      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]'
        end
      end
    end
  end
end
