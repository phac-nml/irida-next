# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class MembersTest < ApplicationSystemTestCase # rubocop:disable Metrics/ClassLength
    def setup
      login_as users(:john_doe)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
      @project = projects(:john_doe_project2)
      @members_count = members.select { |member| member.namespace == @project.namespace }.count
    end

    test 'can see the list of project members' do
      visit namespace_project_members_url(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count
    end

    test 'cannot access project members' do
      login_as users(:david_doe)

      visit namespace_project_members_url(@namespace, @project)

      assert_text I18n.t(:'action_policy.policy.namespaces/project_namespace.member_listing?', name: @project.name)
    end

    test 'can add a member to the project' do
      visit namespace_project_members_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'a', text: I18n.t(:'projects.members.index.add'), count: 1
      click_link I18n.t(:'projects.members.index.add')

      assert_selector 'h2', text: I18n.t(:'projects.members.new.title')

      find('#member_user_id').find(:xpath, 'option[2]').select_option
      find('#member_access_level').find(:xpath, 'option[5]').select_option

      click_button I18n.t(:'projects.members.new.add_member_to_project')

      assert_text I18n.t(:'projects.members.create.success')
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count + 1
    end

    test 'can remove a member from the project' do
      visit namespace_project_members_url(@namespace, @project)

      all('.member-settings-ellipsis')[2].click
      click_link I18n.t(:'projects.members.index.remove')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.members.destroy.success')
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count - 1
    end

    test 'cannot remove themselves as a member from the project' do
      visit namespace_project_members_url(@namespace, @project)

      table_row = find(:xpath, '//table/tbody/tr[1]/td[5]')

      within table_row do
        first('.member-settings-ellipsis').click
        click_link I18n.t(:'projects.members.index.remove')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_no_text I18n.t(:'projects.members.destroy.success')
      assert_text I18n.t('services.members.destroy.cannot_remove_self',
                         namespace_type: @project.namespace.class.model_name.human)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: @members_count
    end

    test 'can create a project under namespace and add a new member to project' do
      project_name = 'New Project'
      project_description = 'New Project Description'

      visit projects_url

      click_on I18n.t(:'projects.index.create_project_button')

      assert_selector 'h1', text: I18n.t(:'projects.new.title')

      within %(div[data-controller="slugify"][data-controller-connected="true"]) do
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
        assert_equal 'new-project',
                     find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).value
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
        click_on I18n.t(:'projects.new.submit')
      end

      assert_selector 'h1', text: project_name
      assert_text project_description

      click_link 'Members'

      click_link I18n.t(:'projects.members.index.add')

      assert_selector 'h2', text: I18n.t(:'projects.members.new.title')

      find('#member_user_id').find(:xpath, 'option[2]').select_option
      find('#member_access_level').find(:xpath, 'option[5]').select_option

      click_button I18n.t(:'projects.members.new.add_member_to_project')

      assert_text I18n.t(:'projects.members.create.success')
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: 1
    end

    test 'can not add a member to the project' do
      login_as users(:ryan_doe)
      visit namespace_project_members_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'a', text: I18n.t(:'projects.members.index.add'), count: 0
    end

    test 'can update member\'s access level to another access level' do
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)

      visit namespace_project_members_url(namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      find("#member-#{project_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t(:'projects.members.update.success', user_email: project_member.user.email)
      end
    end

    test 'cannot update member\'s access level to a lower level than what they have assigned in parent group' do
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_james_doe)

      visit namespace_project_members_url(namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      find("#member-#{project_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t('activerecord.errors.models.member.attributes.access_level.invalid',
                           user: project_member.user.email,
                           access_level: Member::AccessLevel.human_access(Member::AccessLevel::OWNER),
                           group_name: 'Group 5')
      end
    end
  end
end
