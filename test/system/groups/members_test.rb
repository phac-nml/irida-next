# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MembersTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @namespace = groups(:group_one)
      @members_count = members.select { |member| member.namespace == @namespace }.count
    end

    test 'can see the list of group members' do
      visit group_members_url(@namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count
    end

    test 'can add a member to the group' do
      visit group_members_url(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

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

      all('.member-settings-ellipsis')[2].click

      accept_confirm do
        click_link I18n.t(:'groups.members.index.remove')
      end

      assert_text I18n.t(:'groups.members.destroy.success')
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @members_count - 1
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
      assert_selector 'tr', count: @members_count
    end
  end
end
