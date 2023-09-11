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
  end
end
