# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class GroupLinksTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = namespaces_project_namespaces(:project25_namespace)
      @group_links_count = namespace_group_links.select { |group_link| group_link.namespace == @namespace }.count
    end

    test 'can create a project to group link' do
      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      assert_selector 'a', text: I18n.t(:'projects.members.index.invite_group'), count: 1

      click_link I18n.t(:'projects.members.index.invite_group')

      within('span[data-controller-connected="true"] dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.group_links.new.title')
        assert_selector 'p', text: I18n.t(
          :'projects.group_links.new.sharing_namespace_with_group',
          name: @namespace.human_name
        )
        find('#namespace_group_link_group_id').find(:xpath, 'option[2]').select_option
        find('#namespace_group_link_group_access_level').find(:xpath, 'option[3]').select_option

        click_button I18n.t(:'projects.group_links.new.button.submit')
      end

      assert_selector 'tr', count: (@namespace.shared_with_group_links.of_ancestors.count + 1) + header_row_count
    end

    test 'cannot add a project to group link' do
      login_as users(:ryan_doe)
      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')

      assert_selector 'a', text: I18n.t(:'groups.members.index.invite_group'), count: 0
    end

    test 'can remove a project to group link' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.group_links.index.unlink')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'projects.group_links.destroy.success',
                         namespace_name: namespace_group_link.namespace.human_name,
                         group_name: namespace_group_link.group.human_name)

      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count
    end

    test 'cannot remove a project to group link' do
      login_as users(:ryan_doe)
      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      within('table') do
        assert_selector 'button.Viral-Dropdown--icon', count: 0
      end
    end

    test 'cannot remove a project to group link if logged in user has role changed to a level which can\'t modify' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.group_links.index.unlink')
      end

      Member.where(user: @user,
                   namespace: namespace_group_link.namespace.parent&.self_and_ancestor_ids)
            .update(access_level: Member::AccessLevel::GUEST)

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'action_policy.policy.namespaces/project_namespace.unlink_namespace_with_group?',
                         name: namespace_group_link.namespace.name)

      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count
    end
  end
end
