# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class MembersTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
      @project = projects(:john_doe_project2)
      @members_count = members_project_members.select { |member| member.namespace == @project.namespace }.count
    end

    test 'can see the list of project members' do
      visit namespace_project_members_url(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count
    end

    test 'can add a member to the project' do
      visit namespace_project_members_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      click_link I18n.t(:'projects.members.index.add')

      assert_selector 'h2', text: I18n.t(:'projects.members.new.title')

      find('#member_user_id').find(:xpath, 'option[2]').select_option
      find('#member_access_level').find(:xpath, 'option[5]').select_option

      click_button I18n.t(:'projects.members.new.add_member_to_group')

      assert_text I18n.t(:'projects.members.create.success')
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count + 1
    end

    test 'can remove a member from the project' do
      visit namespace_project_members_url(@namespace, @project)

      all('.member-settings-ellipsis')[2].click

      accept_confirm do
        click_link I18n.t(:'projects.members.index.remove')
      end

      assert_text I18n.t(:'projects.members.destroy.success')
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count - 1
    end

    test 'cannot remove themselves as a member from the project' do
      visit namespace_project_members_url(@namespace, @project)

      first('.member-settings-ellipsis').click

      accept_confirm do
        click_link I18n.t(:'projects.members.index.remove')
      end

      assert_no_text I18n.t(:'projects.members.destroy.success')
      assert_text I18n.t('services.members.destroy.cannot_remove_self',
                         namespace_type: @project.namespace.class.model_name.human)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count
    end
  end
end
