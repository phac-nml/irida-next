# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MembersTest < ApplicationSystemTestCase
    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @members_count = members.select { |member| member.namespace == @namespace }.count
    end

    test 'can see the list of group members' do
      visit group_members_url(@namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count
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
      assert_selector 'tr', count: @members_count + 1
    end

    test 'can remove a member from the group' do
      visit group_members_url(@namespace)

      pause
      all('.member-settings-ellipsis')[2].click
      pause
      click_link I18n.t(:'groups.members.index.remove')

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.members.destroy.success')
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count - 1
    end

    test 'cannot remove themselves as a member from the group' do
      visit group_members_url(@namespace)

      all('.member-settings-ellipsis')[0].click
      click_link I18n.t(:'projects.members.index.remove')

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t('services.members.destroy.cannot_remove_self',
                         namespace_type: @namespace.class.model_name.human)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count
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

      visit group_members_url(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      find("#member-#{group_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t(:'groups.members.update.success', user_email: group_member.user.email)
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
