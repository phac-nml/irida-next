# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class GroupLinksTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @group_links_count = namespace_group_links.select { |group_link| group_link.namespace == @namespace }.count
    end

    test 'can create a group to group link' do
      visit group_members_url(@namespace, tab: 'invited_groups')
      assert_selector 'tr', count: @group_links_count + header_row_count

      assert_selector 'a', text: I18n.t(:'groups.members.index.invite_group'), count: 1

      click_link I18n.t(:'groups.members.index.invite_group')

      within('span[data-controller-connected="true"] dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.group_links.new.title')
        assert_selector 'p', text: I18n.t(
          :'groups.group_links.new.sharing_namespace_with_group',
          name: @namespace.human_name
        )
        find('#namespace_group_link_group_id').find(:xpath, 'option[2]').select_option
        find('#namespace_group_link_group_access_level').find(:xpath, 'option[3]').select_option

        click_button I18n.t(:'groups.group_links.new.button.submit')
      end

      assert_selector 'tr', count: (@group_links_count + 1) + header_row_count
    end

    test 'cannot add a group to group link' do
      login_as users(:ryan_doe)
      visit group_members_url(@namespace, tab: 'invited_groups')

      assert_selector 'a', text: I18n.t(:'groups.members.index.invite_group'), count: 0
    end

    test 'can remove a group to group link' do
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      visit group_members_url(@namespace, tab: 'invited_groups')
      assert_selector 'tr', count: @group_links_count + header_row_count

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'groups.group_links.index.unlink')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.group_links.destroy.success', namespace_name: namespace_group_link.namespace.name,
                                                                group_name: namespace_group_link.group.name)

      assert_selector 'tr', count: (@group_links_count - 1) + header_row_count
    end

    test 'cannot remove a group to group link' do
      login_as users(:ryan_doe)
      visit group_members_url(@namespace, tab: 'invited_groups')

      within('table') do
        assert_selector 'button.Viral-Dropdown--icon', count: 0
      end
    end

    test 'cannot remove a group to group link if logged in user has role changed' do
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      visit group_members_url(@namespace, tab: 'invited_groups')
      assert_selector 'tr', count: @group_links_count + header_row_count

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'groups.group_links.index.unlink')
      end

      Member.find_by(user: @user,
                     namespace: namespace_group_link.namespace).update(access_level: Member::AccessLevel::GUEST)

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      pause
      assert_text I18n.t(:'action_policy.policy.group.unlink_namespace_with_group?',
                         name: namespace_group_link.namespace.name)

      assert_selector 'tr', count: @group_links_count + header_row_count
    end
  end
end
