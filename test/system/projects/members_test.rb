# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class MembersTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
      @project = projects(:john_doe_project2)
      @members_count = members.select { |member| member.namespace == @project.namespace }.count
    end

    test 'can see the list of project members' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)
      visit namespace_project_members_url(namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'th', text: I18n.t(:'projects.members.index.table_header.username')

      assert_selector 'tr', count: 20 + header_row_count

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tr', count: 6 + header_row_count

      assert_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/

      click_on I18n.t(:'components.pagination.previous')
      assert_selector 'tr', count: 20 + header_row_count
    end

    test 'can see list of project members which are inherited from parent group' do
      project = projects(:project21)
      parent_namespace = groups(:group_one)
      members_count = members.select { |member| member.namespace == parent_namespace }.count

      visit namespace_project_members_url(parent_namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'th', text: I18n.t(:'projects.members.index.table_header.username')

      assert_selector 'tr', count: members_count + header_row_count

      assert_no_text 'Direct member'
    end

    test 'lists the correct membership when user is a direct member of the project as well as an inherited member
    through a group' do
      project = projects(:project24)
      parent_namespace = groups(:group_one)

      visit namespace_project_members_url(parent_namespace, project)

      group_member = members(:group_one_member_ryan_doe)

      project_member = members(:project_twenty_four_member_ryan_doe)

      assert_equal project_member.user, group_member.user

      # User has membership in group and in project with same access level
      assert_equal Member::AccessLevel::GUEST, group_member.access_level
      assert_equal Member::AccessLevel::GUEST, project_member.access_level

      table_row = find(:table_row, [project_member.user.email])

      within table_row do
        # Should display member as Direct member of project
        assert_text 'Direct member'
        assert_no_text 'Group 1'
      end
    end

    test 'cannot access project members' do
      login_as users(:david_doe)

      visit namespace_project_members_url(@namespace, @project)

      assert_text I18n.t(:'action_policy.policy.namespaces/project_namespace.member_listing?', name: @project.name)
    end

    test 'can add a member to the project' do
      visit namespace_project_members_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      user_to_add = users(:jane_doe)

      assert_selector 'a', text: I18n.t(:'projects.members.index.add'), count: 1
      click_link I18n.t(:'projects.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')

        find('#member_user_id').find('option', text: user_to_add.email).select_option
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'projects.members.new.add_member_to_project')
      end

      assert_text I18n.t(:'projects.members.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: (@members_count + 1) + header_row_count

      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'can remove a member from the project' do
      visit namespace_project_members_url(@namespace, @project)
      project_member = members(:project_two_member_ryan_doe)

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.members.index.remove')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.members.destroy.success', user: project_member.user.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: (@members_count - 1) + header_row_count
    end

    test 'can remove a member from the project that is under a user namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project4)
      visit namespace_project_members_url(namespace, project)
      project_member = members(:project_four_member_joan_doe)
      members_count = members.select { |member| member.namespace == project.namespace }.count

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.members.index.remove')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.members.destroy.success', user: project_member.user.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: (members_count - 1) + header_row_count
    end

    test 'can leave a project that is under a user namespace where user is the only owner "member" of the project' do
      login_as users(:user25)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)

      visit namespace_project_members_url(namespace, project)
      project_member = members(:project_twenty_six_group_member25)

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')

      assert_selector 'th', text: I18n.t(:'projects.members.index.table_header.username')

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.members.index.leave_project')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.members.destroy.leave_success', name: project.name)
      # Redirected to dashboard
      assert_text 'HELLO: Stranger Danger'
    end

    test 'can remove themselves as a member from the project' do
      visit namespace_project_members_url(@namespace, @project)
      table_row = find(:table_row, { 'Username' => @user.email })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.members.index.leave_project')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.members.destroy.leave_success', name: @project.name)
      assert_no_selector 'h1', text: I18n.t(:'projects.members.index.title')
    end

    test 'can create a project under namespace and add a new member to project' do
      project_name = 'New Project'
      project_description = 'New Project Description'
      user_to_add = users(:jane_doe)

      visit dashboard_projects_url

      click_on I18n.t(:'dashboard.projects.index.create_project_button')

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

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')
        find('#member_user_id').find('option', text: user_to_add.email).select_option
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'projects.members.new.add_member_to_project')
      end

      assert_text I18n.t(:'projects.members.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: 1 + header_row_count
      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
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

      Timecop.travel(Time.zone.now + 5) do
        visit namespace_project_members_url(namespace, project)

        assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

        find("#member-#{project_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

        within %(turbo-frame[id="member-update-alert"]) do
          assert_text I18n.t(:'projects.members.update.success', user_email: project_member.user.email)
        end

        project_member_row = find(:table_row, [project_member.user.email])

        within project_member_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
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

    test 'can see the list of namespace group links' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      visit namespace_project_members_url(namespace_group_link.namespace.parent, namespace_group_link.namespace.project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'a', text: I18n.t(:'projects.members.index.tabs.groups')

      click_link I18n.t(:'projects.members.index.tabs.groups')

      assert_selector 'th', text: I18n.t(:'groups.group_links.index.table_header.group')

      assert_selector 'tr', count: 4 + header_row_count

      assert_text I18n.t(:'activerecord.models.namespace_group_link.direct'), count: 1

      parent_namespace_group_link = namespace_group_link.namespace.parent
      assert_not_nil find(:table_row, { 'Source' => parent_namespace_group_link.name })

      parent_namespace_group_link = namespace_group_link.namespace.parent.parent

      assert_not_nil find(:table_row, { 'Group' => 'Group 4', 'Source' => parent_namespace_group_link.name })
      assert_not_nil find(:table_row, { 'Group' => 'Group 11', 'Source' => parent_namespace_group_link.name })
    end

    test 'can update member expiration' do
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)
      expiry_date = (Time.zone.today + 1).strftime('%Y-%m-%d')

      visit namespace_project_members_url(namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      find("#project-member-#{project_member.id}-expiration").click.set(expiry_date)
                                                             .native.send_keys(:return)

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t(:'projects.members.update.success', user_email: project_member.user.email)
      end

      project_member_row = find(:table_row, [project_member.user.email])

      within project_member_row do
        assert_text 'Updated', count: 1
        assert_text 'less than a minute ago'
      end
    end

    test 'cannot update member expiration' do
      login_as users(:ryan_doe)

      visit namespace_project_members_url(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      within('table') do
        assert_selector 'input.datepicker-input', count: 0
      end
    end
  end
end
