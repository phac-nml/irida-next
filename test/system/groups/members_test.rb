# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MembersTest < ApplicationSystemTestCase # rubocop:disable Metrics/ClassLength
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @members_count = members.select { |member| member.namespace == @namespace }.count
    end

    test 'can see the list of group members' do
      visit group_members_url(@namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count + header_row_count
    end

    test 'can see list of group members for subgroup which are inherited from parent group' do
      namespace = groups(:subgroup1)

      visit group_members_url(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count + header_row_count

      assert_no_text 'Direct member'
    end

    test 'lists the correct membership when user is a direct member of the group as well as an inherited member
    through a group' do
      namespace = groups(:subgroup_one_group_three)

      visit group_members_url(namespace)

      group_member = members(:group_three_member_micha_doe)
      subgroup_member = members(:subgroup_one_group_three_member_micha_doe)

      assert_equal subgroup_member.user, group_member.user

      # User has membership in group and in subgroup with same access level
      assert_equal Member::AccessLevel::MAINTAINER, group_member.access_level
      assert_equal Member::AccessLevel::MAINTAINER, subgroup_member.access_level

      table_row = find(:table_row, [subgroup_member.user.email])

      within table_row do
        # Should display member as Direct member of subgroup
        assert_text 'Direct member'
        assert_no_text 'Group 3'
      end
    end

    test 'cannot access group members' do
      login_as users(:david_doe)

      visit group_members_url(@namespace)

      assert_text I18n.t(:'action_policy.policy.group.member_listing?', name: @namespace.name)
    end

    test 'can add a member to the group' do
      visit group_members_url(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.add'), count: 1

      click_link I18n.t(:'groups.members.index.add')

      assert_selector 'h2', text: I18n.t(:'groups.members.new.title')

      find('#member_user_id').find(:xpath, 'option[2]').select_option
      find('#member_access_level').find(:xpath, 'option[5]').select_option

      click_button I18n.t(:'groups.members.new.add_member_to_group')

      assert_text I18n.t(:'groups.members.create.success')
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: (@members_count + 1) + header_row_count
    end

    test 'can remove a member from the group' do
      visit group_members_url(@namespace)

      all('.member-settings-ellipsis')[2].click

      accept_confirm do
        click_link I18n.t(:'groups.members.index.remove')
      end

      assert_text I18n.t(:'groups.members.destroy.success')
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: (@members_count - 1) + header_row_count
    end

    test 'cannot remove themselves as a member from the group' do
      visit group_members_url(@namespace)

      first('.member-settings-ellipsis').click

      accept_confirm do
        click_link I18n.t(:'groups.members.index.remove')
      end

      assert_no_text I18n.t(:'groups.members.destroy.success')
      assert_text I18n.t('services.members.destroy.cannot_remove_self',
                         namespace_type: @namespace.class.model_name.human)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count + header_row_count
    end

    test 'can not add a member to the group' do
      login_as users(:ryan_doe)
      visit group_members_url(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.add'), count: 0
    end

    test 'can update member\'s access level to another access level' do
      namespace = groups(:group_five)
      group_member = members(:group_five_member_michelle_doe)

      Timecop.travel(Time.zone.now + 5) do
        visit group_members_url(namespace)

        assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

        find("#member-#{group_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

        within %(turbo-frame[id="member-update-alert"]) do
          assert_text I18n.t(:'groups.members.update.success', user_email: group_member.user.email)
        end

        group_member_row = find(:table_row, [group_member.user.email])

        within group_member_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
      end
    end

    test 'cannot update member\'s access level to a lower level than what they have assigned in parent group' do
      namespace = groups(:subgroup_one_group_five)
      group_member = members(:subgroup_one_group_five_member_james_doe)

      visit group_members_url(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      find("#member-#{group_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t('activerecord.errors.models.member.attributes.access_level.invalid',
                           user: group_member.user.email,
                           access_level: Member::AccessLevel.human_access(Member::AccessLevel::OWNER),
                           group_name: 'Group 5')
      end
    end
  end
end
