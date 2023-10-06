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

    test 'cannot remove a project to group link that may have been unlinked in another tab' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      namespace_group_link.destroy

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        first('button.Viral-Dropdown--icon').click
        click_link I18n.t(:'projects.group_links.index.unlink')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text 'Resource not found'
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

      member_namespace_ids_to_update = @namespace.shared_with_group_links.of_ancestors.pluck(:group_id) +
                                       namespace_group_link.namespace.parent&.self_and_ancestors&.ids +
                                       [namespace_group_link.namespace.id]

      Member.where(user: @user,
                   namespace: member_namespace_ids_to_update).update(access_level: Member::AccessLevel::GUEST)

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'action_policy.policy.namespaces/project_namespace.unlink_namespace_with_group?',
                         name: namespace_group_link.namespace.name)

      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count
    end

    test 'can update namespace group links group access level to another access level' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)

      Timecop.travel(Time.zone.now + 5) do
        visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
        assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

        find("#invited-group-#{namespace_group_link.group.id}-access-level-select").find(:xpath,
                                                                                         'option[2]').select_option

        assert_text I18n.t(:'projects.group_links.update.success',
                           namespace_name: namespace_group_link.namespace.human_name,
                           group_name: namespace_group_link.group.human_name,
                           param_name: 'group access level')

        namespace_group_link_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

        within namespace_group_link_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
      end
    end

    test 'cannot update namespace group links group access level' do
      login_as users(:ryan_doe)

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      within('table') do
        assert_selector 'select', count: 0
      end
    end

    test 'can update namespace group links expiration' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)
      expiry_date = (Time.zone.today + 7).strftime('%Y-%m-%d')

      Timecop.travel(Time.zone.now + 5) do
        visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
        assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

        find("#invited-group-#{namespace_group_link.group.id}-expiration").click.set(expiry_date)
                                                                          .native.send_keys(:return)

        assert_text I18n.t(:'projects.group_links.update.success',
                           namespace_name: namespace_group_link.namespace.human_name,
                           group_name: namespace_group_link.group.human_name,
                           param_name: 'expiration')

        namespace_group_link_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

        within namespace_group_link_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
      end
    end

    test 'cannot update namespace group links expiration' do
      login_as users(:ryan_doe)

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      within('table') do
        assert_selector 'input.datepicker-input', count: 0
      end
    end

    test 'cannot update namespace group link which may have been deleted in another tab' do
      namespace_group_link = namespace_group_links(:namespace_group_link3)
      expiry_date = (Time.zone.today + 7).strftime('%Y-%m-%d')

      visit namespace_project_members_url(@namespace.parent, @namespace.project, tab: 'invited_groups')
      assert_selector 'tr', count: @namespace.shared_with_group_links.of_ancestors.count + header_row_count

      namespace_group_link.destroy

      find("#invited-group-#{namespace_group_link.group.id}-expiration").click.set(expiry_date)
                                                                        .native.send_keys(:return)

      assert_text 'Resource not found'
    end

    test 'group member of Group B can access Group A projects as it is shared with Group A' do
      login_as users(:user24)

      namespace_group_link = namespace_group_links(:namespace_group_link10)

      visit namespace_project_url(namespace_group_link.namespace.parent,
                                  namespace_group_link.namespace.project)

      assert_no_text I18n.t(:'action_policy.policy.project.read?',
                            name: namespace_group_link.namespace.name)

      assert_selector 'h1', text: namespace_group_link.namespace.name, count: 1
      assert_selector 'p', text: namespace_group_link.namespace.description, count: 1
    end

    test 'group member of Group B cannot access Group C projects as it is not shared with Group B' do
      login_as users(:user24)

      namespace_group_link = namespace_group_links(:namespace_group_link11)

      visit namespace_project_url(namespace_group_link.namespace.parent,
                                  namespace_group_link.namespace.project)

      assert_text I18n.t(:'action_policy.policy.project.read?',
                         name: namespace_group_link.namespace.name)
    end

    test 'group member of Group C cannot see Group A projects' do
      login_as users(:user25)

      no_access_namespace_group_link = namespace_group_links(:namespace_group_link10)

      visit namespace_project_url(no_access_namespace_group_link.namespace.parent,
                                  no_access_namespace_group_link.namespace.project)

      assert_text I18n.t(:'action_policy.policy.project.read?',
                         name: no_access_namespace_group_link.namespace.name)
    end

    test 'group member of Group A cannot see Group C projects' do
      login_as users(:john_doe)

      no_access_namespace_group_link = namespace_group_links(:namespace_group_link11)

      visit namespace_project_url(no_access_namespace_group_link.namespace.parent,
                                  no_access_namespace_group_link.namespace.project)

      assert_text I18n.t(:'action_policy.policy.project.read?',
                         name: no_access_namespace_group_link.namespace.name)
    end

    test 'group member of Group B cannot access Group A projects as the access has expired' do
      login_as users(:user24)

      namespace_group_link = namespace_group_links(:namespace_group_link10)

      NamespaceGroupLink.where(namespace: [namespace_group_link.namespace, namespace_group_link.namespace.parent],
                               group: namespace_group_link.group).update(expires_at: Time.zone.today - 1)

      visit namespace_project_url(namespace_group_link.namespace.parent,
                                  namespace_group_link.namespace.project)

      assert_text I18n.t(:'action_policy.policy.project.read?',
                         name: namespace_group_link.namespace.name)
    end
  end
end
