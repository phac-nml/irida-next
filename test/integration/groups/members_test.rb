# frozen_string_literal: true

require 'test_helper'

module Groups
  class MembersTest < ActionDispatch::IntegrationTest
    PAGE_SIZE = Pagy::OPTIONS[:limit]

    def setup
      @user = users(:john_doe)
      @namespace = groups(:group_one)
      @members_count = members.select { |member| member.namespace == @namespace }.count
      @member_john = members(:group_one_member_john_doe)
      @member_james = members(:group_one_member_james_doe)
      @member_joan = members(:group_one_member_joan_doe)
      @member_ryan = members(:group_one_member_ryan_doe)
      @member_bot = members(:group_one_member_user_bot_account)
    end

    test 'can see the list of group members' do
      sign_in @user
      namespace = groups(:group_seven)

      get group_members_path(namespace)

      assert_response :success

      assert_select 'h1', text: I18n.t(:'groups.members.index.title')
      assert_select 'button', text: I18n.t(:'groups.members.index.add')

      assert_select "turbo-frame#members[src='#{group_members_path(
        namespace,
        format: :turbo_stream
      )}'][loading='lazy']"

      get group_members_path(namespace), as: :turbo_stream

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: PAGE_SIZE
            end
          end
        end
      end
      assert_select 'turbo-stream[action="update"][target="members_pagination"]' do
        assert_select 'span', text: 'Next'
      end
    end

    test 'can see list of group members for subgroup which are inherited from parent group' do
      sign_in @user
      namespace = groups(:subgroup1)

      get group_members_path(namespace), as: :turbo_stream

      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: @members_count
            end
          end
        end
      end
    end

    test 'lists the correct membership when user is a direct member of the group as well as an inherited member through a group' do # rubocop:disable Layout/LineLength
      sign_in @user
      namespace = groups(:subgroup_one_group_three)
      members(:group_three_member_micha_doe)
      subgroup_member = members(:subgroup_one_group_three_member_micha_doe)

      get group_members_path(namespace), as: :turbo_stream

      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select "tr#member_#{subgroup_member.id}" do
                assert_select 'td:nth-child(3)', text: 'Direct member', count: 1
              end
            end
          end
        end
      end
    end

    test 'cannot access group members' do
      sign_in users(:user_no_access)

      get group_members_path(@namespace)

      assert_response :unauthorized
    end

    test 'can add a member to the group' do
      sign_in @user
      user_to_add = users(:jane_doe)

      get group_members_path(@namespace)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_group_member_path(@namespace)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: 'Add New Member'
        end
      end

      assert_difference -> { @namespace.group_members.count } do
        post group_members_path(@namespace),
             params: { member: {
               user_id: user_to_add.id,
               namespace_id: @namespace.id,
               created_by_id: @user.id,
               access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :success
    end

    test 'invalid member create focuses the summary and linked custom control' do
      sign_in @user

      get group_members_path(@namespace)
      assert_response :success

      I18n.t(:'errors.format',
             attribute: Member.human_attribute_name(:user_id),
             message: I18n.t(:'errors.messages.required'))

      post group_members_path(@namespace),
           params: { member: {
             access_level: Member::AccessLevel::ANALYST
           } },
           as: :turbo_stream

      assert_response :unprocessable_entity
      assert_select 'turbo-stream[action="update"][target="flashes"]', count: 0
    end

    test 'can remove a member from the group' do
      sign_in @user
      group_member = members(:group_one_member_joan_doe)

      assert_difference -> { @namespace.group_members.count }, -1 do
        delete group_member_path(@namespace, group_member), as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]'
        end
      end
    end

    test 'can remove themselves as a member from the group' do
      sign_in @user

      assert_difference -> { @namespace.group_members.count }, -1 do
        delete group_member_path(@namespace, @member_john), as: :turbo_stream
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.membership_actions.destroy.leave_success', name: @namespace.name
                      )}"
      end
    end

    test 'can not add a member to the group' do
      sign_in users(:ryan_doe)

      get group_members_path(@namespace)
      assert_response :success

      assert_select 'button', text: I18n.t(:'groups.members.index.add'), count: 0
    end

    test 'can update member\'s access level to another access level' do
      sign_in @user
      namespace = groups(:group_five)
      group_member = members(:group_five_member_michelle_doe)

      get edit_group_member_path(namespace, group_member), as: :turbo_stream
      assert_response :success

      Timecop.travel(Time.zone.now + 5) do
        patch group_member_path(namespace, group_member),
              params: { member: {
                access_level: Member::AccessLevel::ANALYST
              }, format: :turbo_stream }

        assert_response :success

        assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
          assert_select 'div',
                        "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.update.success',
                                                                        user_email: group_member.user.email)}"
        end
      end
    end

    test 'cannot update member\'s access level to a lower level than what they have assigned in parent group' do
      sign_in @user
      namespace = groups(:subgroup_one_group_five)
      group_member = members(:subgroup_one_group_five_member_james_doe)

      patch group_member_path(namespace, group_member),
            params: { member: {
              access_level: Member::AccessLevel::GUEST
            } },
            as: :turbo_stream

      assert_response :unprocessable_entity
    end

    test 'can update member expiration' do
      sign_in @user
      group_member = members(:group_one_member_joan_doe)
      expiry_date = (Time.zone.today + 1).strftime('%Y-%m-%d')

      get edit_group_member_path(@namespace, group_member), as: :turbo_stream
      assert_response :success

      patch group_member_path(@namespace, group_member), params: {
        member: {
          expires_at: expiry_date
        }, format: :turbo_stream
      }

      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.update.success',
                                                                      user_email: group_member.user.email)}"
      end
    end

    test 'cannot update membership' do
      sign_in users(:ryan_doe)
      group_member = members(:group_one_member_joan_doe)

      get edit_group_member_path(@namespace, group_member), as: :turbo_stream
      assert_response :unauthorized

      assert_no_difference -> { group_member.reload.access_level } do
        patch group_member_path(@namespace, group_member),
              params: { member: {
                access_level: Member::AccessLevel::ANALYST
              } },
              as: :turbo_stream

        assert_response :unauthorized
      end
    end

    test 'can add a group bot to a group' do
      sign_in users(:user30)
      namespace_bot = namespace_bots(:group1_bot0)
      namespace = groups(:user30_group_one)
      user_to_add = namespace_bot.user

      get group_members_path(namespace)
      assert_response :success

      assert_difference -> { namespace.group_members.count } do
        post group_members_path(namespace),
             params: { member: {
               user_id: user_to_add.id,
               namespace_id: namespace.id,
               created_by_id: users(:user30).id,
               access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.create.success',
                                                                      user: namespace_bot.user.email)}"
      end
    end

    test 'cannot add a project bot to a group' do
      sign_in users(:user30)
      namespace_bot = namespace_bots(:project1_bot0)
      namespace = groups(:user30_group_one)

      get group_members_path(namespace)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_group_member_path(namespace)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: 'Add New Member'
        end
      end

      assert_no_difference -> { namespace.group_members.count } do
        post group_members_path(namespace),
             params: { member: {
               user_id: namespace_bot.user.id,
               namespace_id: namespace.id,
               created_by_id: users(:user30).id,
               access_level: Member::AccessLevel::UPLOADER
             } },
             as: :turbo_stream
      end

      assert_response :unprocessable_entity
    end

    test 'can search members by username' do
      sign_in @user

      get group_members_path(@namespace), as: :turbo_stream
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: 5
            end
          end
        end
      end

      get group_members_path(@namespace), params: { members_q: { user_email_cont: @member_james.user.email } },
                                          as: :turbo_stream
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: 1
            end
          end
        end
      end
    end

    test 'can switch between members and shared groups tabs' do
      sign_in @user

      get group_members_path(@namespace)
      assert_response :success

      # Members tab should be rendered and be the default
      assert_select '[role="tab"]#members-tab[aria-selected="true"]'
      assert_select '[role="tabpanel"]#members-panel:not([hidden])'
      assert_select '[role="tab"]#groups-tab[aria-selected="false"]'

      get group_members_path(@namespace, tab: 'invited_groups')
      assert_response :success

      assert_select '[role="tab"]#members-tab[aria-selected="false"]'
      assert_select '[role="tabpanel"]#members-panel[hidden]'
      assert_select '[role="tab"]#groups-tab[aria-selected="true"]'
      assert_select '[role="tabpanel"]#groups-panel:not([hidden])'
    end
  end
end
