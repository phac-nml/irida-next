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
      @member_john = members(:project_two_member_john_doe)
      @member_james = members(:project_two_member_james_doe)
      @member_joan = members(:project_two_member_joan_doe)
      @member_jean = members(:project_two_member_jean_doe)
      @member_ryan = members(:project_two_member_ryan_doe)
    end

    test 'can see the list of project members' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)
      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'th', text: I18n.t(:'members.table_component.user_email').upcase

      within('#members') do
        assert_selector 'tr', count: 20 + header_row_count
      end

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')

      within('#members') do
        assert_selector 'tr', count: 6 + header_row_count
      end

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')

      click_on I18n.t(:'components.viral.pagy.pagination_component.previous')

      within('#members') do
        assert_selector 'tr', count: 20 + header_row_count
      end
    end

    test 'can see list of project members which are inherited from parent group' do
      project = projects(:project21)
      parent_namespace = groups(:group_one)
      members_count = members.select { |member| member.namespace == parent_namespace }.count

      visit namespace_project_members_url(parent_namespace, project)
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'th', text: I18n.t(:'members.table_component.user_email').upcase, wait: 10

      assert_selector 'tr', count: members_count + header_row_count

      assert_no_text 'Direct member'
    end

    test 'lists the correct membership when user is a direct member of the project as well as an inherited member
    through a group' do
      project = projects(:project24)
      parent_namespace = groups(:group_one)

      visit namespace_project_members_url(parent_namespace, project)
      wait_for_network_idle

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
      wait_for_network_idle

      assert_text I18n.t(:'action_policy.policy.namespaces/project_namespace.member_listing?', name: @project.name)
    end

    test 'can add a member to the project' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      user_to_add = users(:jane_doe)

      assert_selector 'button', text: I18n.t(:'projects.members.index.add'), count: 1
      click_button I18n.t(:'projects.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')

        find('input.select2-input').click
        find("li[data-value='#{user_to_add.id}']").click
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'projects.members.new.add_member_to_project')
      end

      assert_text I18n.t(:'concerns.membership_actions.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector '#members', wait: 10
      within('#members') do
        assert_selector 'tr', count: (@members_count + 1) + header_row_count
      end

      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'can remove a member from the project' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle
      project_member = members(:project_two_member_ryan_doe)

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        click_button I18n.t('common.actions.remove')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t('common.controls.confirm')
      end

      assert_text I18n.t(:'concerns.membership_actions.destroy.success', user: project_member.user.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: (@members_count - 1) + header_row_count
    end

    test 'can remove a member from the project that is under a user namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project4)
      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle
      project_member = members(:project_four_member_joan_doe)

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        click_button I18n.t('common.actions.remove')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t('common.controls.confirm')
      end

      assert_text I18n.t(:'concerns.membership_actions.destroy.success', user: project_member.user.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_text I18n.t(:'projects.members.index.empty_state.title')
    end

    test 'can leave a project that is under a user namespace where user is the only owner "member" of the project' do
      login_as users(:user25)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)

      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle
      project_member = members(:project_twenty_six_group_member25)

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      assert_selector 'th', text: I18n.t(:'members.table_component.user_email').upcase

      table_row = find(:table_row, { 'Username' => project_member.user.email })

      within table_row do
        click_button I18n.t(:'projects.members.index.leave_project')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t('common.controls.confirm')
      end

      assert_text I18n.t(:'concerns.membership_actions.destroy.leave_success', name: project.name)
      assert_text I18n.t(:'dashboard.projects.index.title')
    end

    test 'can remove themselves as a member from the project' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle
      table_row = find(:table_row, { 'Username' => @user.email })

      within table_row do
        click_button I18n.t(:'projects.members.index.leave_project')
      end

      within('#turbo-confirm[open]') do
        click_button I18n.t('common.controls.confirm')
      end

      assert_text I18n.t(:'concerns.membership_actions.destroy.leave_success', name: @project.name)
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
        fill_in I18n.t('projects.new.select_namespace'), with: @user.email[0, 4]
        find('ul > li:first-child').click
        assert_equal 'new-project',
                     find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).value
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
        click_on I18n.t(:'projects.new.submit')
      end

      assert_selector 'h1', text: project_name

      new_project = @user.namespace.project_namespaces.find_by(name: project_name).project
      assert_current_path(namespace_project_path(new_project.parent, new_project))

      click_link 'Members'

      click_button I18n.t(:'projects.members.index.add')

      assert_selector 'dialog[open]', visible: true

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')

        find('input.select2-input').click
        find("li[data-value='#{user_to_add.id}']").click
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'projects.members.new.add_member_to_project')
      end

      assert_text I18n.t(:'concerns.membership_actions.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: 1 + header_row_count
      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'can not add a member to the project' do
      login_as users(:ryan_doe)
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector 'a', text: I18n.t(:'projects.members.index.add'), count: 0
    end

    test 'can update member\'s access level to another access level' do
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)

      Timecop.travel(Time.zone.now + 5) do
        visit namespace_project_members_url(namespace, project)
        wait_for_network_idle

        assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

        assert_selector "#member-#{project_member.id}-access-level-select", wait: 10
        find("#member-#{project_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

        within %(turbo-frame[id="member-update-alert"]) do
          assert_text I18n.t(:'concerns.membership_actions.update.success', user_email: project_member.user.email)
        end
      end
    end

    test 'cannot update member\'s access level to a lower level than what they have assigned in parent group' do
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_james_doe)

      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle

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
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      assert_selector '[role="tab"]', text: I18n.t(:'projects.members.index.tabs.groups')

      click_on I18n.t(:'projects.members.index.tabs.groups')

      assert_selector 'th', text: I18n.t(:'groups.table_component.group_name').upcase, wait: 10

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
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      find("#member-#{project_member.id}-expiration-input").click.set(expiry_date)
                                                           .native.send_keys(:return)

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t(:'concerns.membership_actions.update.success', user_email: project_member.user.email)
      end

      within "#member_#{project_member.id}" do
        assert_selector 'button', text: I18n.t('common.actions.remove'), focused: true
      end
    end

    test 'cannot update member expiration' do
      login_as users(:ryan_doe)

      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')

      within('table') do
        assert_selector 'input.datepicker-input', count: 0
      end
    end

    test 'can add a group bot to a project' do
      login_as users(:user29)

      namespace_bot = namespace_bots(:group1_bot0)
      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)
      members_count = members.select { |member| member.namespace == project.namespace }.count

      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      user_to_add = namespace_bot.user

      assert_selector 'button', text: I18n.t(:'projects.members.index.add'), count: 1
      click_button I18n.t(:'projects.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')

        find('input.select2-input').click
        find("li[data-value='#{user_to_add.id}']").click
        find('#member_access_level')
          .find('option',
                text: I18n.t('activerecord.models.member.access_level.uploader')).select_option

        click_button I18n.t(:'projects.members.new.add_member_to_project')
      end

      assert_text I18n.t(:'concerns.membership_actions.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      assert_selector 'tr', count: (members_count + 1) + header_row_count

      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'cannot add a project bot to another project' do
      login_as users(:user29)

      namespace_bot = namespace_bots(:project1_bot0)
      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)

      visit namespace_project_members_url(namespace, project)
      wait_for_network_idle

      assert_selector 'h1', text: I18n.t(:'projects.members.index.title')
      user_to_add = namespace_bot.user

      assert_selector 'button', text: I18n.t(:'projects.members.index.add'), count: 1
      click_button I18n.t(:'projects.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.members.new.title')

        find('input.select2-input').click
        assert_no_selector "li[data-value='#{user_to_add.id}']"
      end
    end

    test 'can search members by username' do
      username_col = 1
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      assert_text 'Displaying 5 items'
      assert_selector 'table tbody tr', count: 5
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_james.user.email
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_jean.user.email
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_joan.user.email
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_john.user.email
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_ryan.user.email

      fill_in placeholder: I18n.t(:'projects.members.member_listing.search.placeholder'),
              with: @member_james.user.email
      find('input.t-search-component').native.send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1
      assert_selector "table tbody tr td:nth-child(#{username_col})", text: @member_james.user.email
      assert_no_selector "table tbody tr td:nth-child(#{username_col})", text: @member_jean.user.email
      assert_no_selector "table tbody tr td:nth-child(#{username_col})", text: @member_joan.user.email
      assert_no_selector "table tbody tr td:nth-child(#{username_col})", text: @member_john.user.email
      assert_no_selector "table tbody tr td:nth-child(#{username_col})", text: @member_ryan.user.email
    end

    test 'can sort members by column' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      assert_text 'Displaying 5 items'
      assert_selector 'table tbody tr', count: 5
      assert_selector 'table thead th:first-child svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: @member_james.user.email
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_james.access_level)
        assert_selector 'tr:nth-child(2) td:first-child', text: @member_jean.user.email
        assert_selector 'tr:nth-child(2) td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_jean.access_level)
        assert_selector 'tr:last-child td:first-child', text: @member_ryan.user.email
        assert_selector 'tr:last-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_ryan.access_level)
      end

      click_on I18n.t('members.table_component.user_email')
      assert_selector 'table thead th:first-child svg.arrow-down-icon'
      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: @member_ryan.user.email
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_ryan.access_level)
        assert_selector 'tr:nth-child(2) td:first-child', text: @member_john.user.email
        assert_selector 'tr:nth-child(2) td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_john.access_level)
        assert_selector 'tr:last-child td:first-child', text: @member_james.user.email
        assert_selector 'tr:last-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_james.access_level)
      end

      click_on I18n.t('members.table_component.access_level')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      within('table tbody') do
        # Ryan is a Guest
        assert_selector 'tr:first-child td:first-child', text: @member_ryan.user.email
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_ryan.access_level)
        # Jean & Joan are Maintainers
        assert_selector 'tr:nth-child(2) td:first-child', text: /#{@member_jean.user.email}|#{@member_joan.user.email}/
        assert_selector 'tr:nth-child(2) td:nth-child(2)',
                        text: /#{Member::AccessLevel.human_access(@member_jean.access_level)}|#{Member::AccessLevel.human_access(@member_joan.access_level)}/ # rubocop:disable Layout/LineLength
        # John & James are Owners
        assert_selector 'tr:last-child td:first-child', text: /#{@member_james.user.email}|#{@member_john.user.email}/
        assert_selector 'tr:last-child td:nth-child(2)',
                        text: /#{Member::AccessLevel.human_access(@member_james.access_level)}|#{Member::AccessLevel.human_access(@member_john.access_level)}/ # rubocop:disable Layout/LineLength
      end

      click_on I18n.t('members.table_component.access_level')
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'
      within('table tbody') do
        # John & James are Owners
        assert_selector 'tr:first-child td:first-child', text: /#{@member_james.user.email}|#{@member_john.user.email}/
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: /#{Member::AccessLevel.human_access(@member_james.access_level)}|#{Member::AccessLevel.human_access(@member_john.access_level)}/ # rubocop:disable Layout/LineLength
        # Jean & Joan are Maintainers
        assert_selector 'tr:nth-child(4) td:first-child', text: /#{@member_jean.user.email}|#{@member_joan.user.email}/
        assert_selector 'tr:nth-child(4) td:nth-child(2)',
                        text: /#{Member::AccessLevel.human_access(@member_jean.access_level)}|#{Member::AccessLevel.human_access(@member_joan.access_level)}/ # rubocop:disable Layout/LineLength
        # Ryan is a Guest
        assert_selector 'tr:last-child td:first-child', text: @member_ryan.user.email
        assert_selector 'tr:last-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_ryan.access_level)
      end

      click_on I18n.t('members.table_component.expires_at')
      assert_selector 'table thead th:nth-child(5) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: @member_joan.user.email
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_joan.access_level)
        assert_selector 'tr:nth-child(2) td:first-child', text: @member_ryan.user.email
        assert_selector 'tr:nth-child(2) td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_ryan.access_level)
        assert_selector 'tr:last-child td:first-child', text: @member_john.user.email
        assert_selector 'tr:last-child td:nth-child(2)',
                        text: Member::AccessLevel.human_access(@member_john.access_level)
      end
    end

    # Pathogen Tabs Component Tests
    test 'tabs component switches between members and groups with click' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Members tab should be selected by default
      assert_selector '[role="tab"]#members-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#members-panel:not(.hidden)'
      assert_selector '[role="tab"]#groups-tab[aria-selected="false"]'
      assert_selector '[role="tabpanel"]#groups-panel.hidden'

      # Click groups tab
      find('[role="tab"]#groups-tab').click
      wait_for_network_idle

      # Groups tab should now be selected
      assert_selector '[role="tab"]#groups-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#groups-panel:not(.hidden)'
      assert_selector '[role="tab"]#members-tab[aria-selected="false"]'
      assert_selector '[role="tabpanel"]#members-panel.hidden'

      # Click members tab again
      find('[role="tab"]#members-tab').click
      wait_for_network_idle

      # Members tab should be selected again
      assert_selector '[role="tab"]#members-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#members-panel:not(.hidden)'
    end

    test 'tabs component supports keyboard navigation with arrow keys' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Focus the first tab
      members_tab = find('[role="tab"]#members-tab')
      members_tab.send_keys(:tab) # Focus the element

      # Press ArrowRight to move to groups tab
      members_tab.send_keys(:arrow_right)

      # Groups tab should now be selected (automatic activation)
      assert_selector '[role="tab"]#groups-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#groups-panel:not(.hidden)'

      # Press ArrowLeft to move back to members tab
      groups_tab = find('[role="tab"]#groups-tab')
      groups_tab.send_keys(:arrow_left)

      # Members tab should be selected again
      assert_selector '[role="tab"]#members-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#members-panel:not(.hidden)'
    end

    test 'tabs component supports Home and End keys for navigation' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Focus and navigate to groups tab first
      members_tab = find('[role="tab"]#members-tab')
      members_tab.send_keys(:arrow_right)

      # Press Home key to go to first tab
      groups_tab = find('[role="tab"]#groups-tab')
      groups_tab.send_keys(:home)

      # Should be on members tab (first tab)
      assert_selector '[role="tab"]#members-tab[aria-selected="true"]'

      # Press End key to go to last tab
      members_tab = find('[role="tab"]#members-tab')
      members_tab.send_keys(:end)

      # Should be on groups tab (last tab)
      assert_selector '[role="tab"]#groups-tab[aria-selected="true"]'
    end

    test 'tabs component syncs selection with URL hash' do
      # Visit with hash for groups tab
      visit namespace_project_members_url(@namespace, @project, anchor: 'groups-tab')
      wait_for_network_idle

      # Groups tab should be selected based on hash
      assert_selector '[role="tab"]#groups-tab[aria-selected="true"]'
      assert_selector '[role="tabpanel"]#groups-panel:not(.hidden)'

      # Click members tab
      find('[role="tab"]#members-tab').click
      wait_for_network_idle

      # URL hash should update
      assert_current_path namespace_project_members_path(@namespace, @project, anchor: 'members-tab')
    end

    test 'tabs component loads content via Turbo Frame lazy loading' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Initially, only members panel content should be loaded
      assert_selector '[role="tabpanel"]#members-panel turbo-frame#members'

      # Switch to groups tab
      find('[role="tab"]#groups-tab').click
      wait_for_network_idle

      # Groups panel turbo frame should now be loaded
      assert_selector '[role="tabpanel"]#groups-panel turbo-frame#invited_groups'
    end

    test 'tabs component maintains ARIA relationships' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Check ARIA attributes on members tab
      members_tab = find('[role="tab"]#members-tab')
      assert_equal 'members-panel', members_tab['aria-controls']
      assert_equal 'true', members_tab['aria-selected']

      # Check ARIA attributes on members panel
      members_panel = find('[role="tabpanel"]#members-panel')
      assert_equal 'members-tab', members_panel['aria-labelledby']
      assert_equal 'false', members_panel['aria-hidden']

      # Check ARIA attributes on groups tab
      groups_tab = find('[role="tab"]#groups-tab')
      assert_equal 'groups-panel', groups_tab['aria-controls']
      assert_equal 'false', groups_tab['aria-selected']

      # Check ARIA attributes on groups panel
      groups_panel = find('[role="tabpanel"]#groups-panel')
      assert_equal 'groups-tab', groups_panel['aria-labelledby']
      assert_equal 'true', groups_panel['aria-hidden']
    end

    test 'tabs component maintains roving tabindex pattern' do
      visit namespace_project_members_url(@namespace, @project)
      wait_for_network_idle

      # Members tab (selected) should have tabindex="0"
      members_tab = find('[role="tab"]#members-tab')
      assert_equal '0', members_tab['tabindex']

      # Groups tab (unselected) should have tabindex="-1"
      groups_tab = find('[role="tab"]#groups-tab')
      assert_equal '-1', groups_tab['tabindex']

      # Click groups tab
      groups_tab.click
      wait_for_network_idle

      # Now groups tab should have tabindex="0"
      assert_equal '0', find('[role="tab"]#groups-tab')['tabindex']
      # And members tab should have tabindex="-1"
      assert_equal '-1', find('[role="tab"]#members-tab')['tabindex']
    end
  end
end
