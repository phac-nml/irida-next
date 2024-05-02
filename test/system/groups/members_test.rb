# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MembersTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @members_count = members.select { |member| member.namespace == @namespace }.count
    end

    test 'can see the list of group members' do
      namespace = groups(:group_seven)

      visit group_members_url(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'th', text: I18n.t(:'groups.members.index.table_header.username').upcase

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

    test 'can see list of group members for subgroup which are inherited from parent group' do
      namespace = groups(:subgroup1)

      visit group_members_url(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'th', text: I18n.t(:'groups.members.index.table_header.username').upcase

      assert_selector 'tr', count: @members_count + header_row_count

      assert_text 'Direct member', count: 1
    end

    test 'lists the correct membership when user is a direct member of the group as well as an inherited member
    through a group' do
      namespace = groups(:subgroup_one_group_three)

      visit group_members_url(namespace)

      group_member = members(:group_three_member_micha_doe)
      subgroup_member = members(:subgroup_one_group_three_member_micha_doe)

      assert_equal subgroup_member.user, group_member.user

      # User has membership in group and in subgroup with same access level
      assert_equal Member::AccessLevel::MAINTAINER, group_member.access_level
      assert_equal Member::AccessLevel::MAINTAINER, subgroup_member.access_level

      table_row = find(:table_row, [subgroup_member.user.email])

      within table_row do
        # Should display member as Direct member of subgroup
        assert_text 'Direct member'
        assert_no_text 'Group 3'
      end
    end

    test 'cannot access group members' do
      login_as users(:user_no_access)

      visit group_members_url(@namespace)

      assert_text I18n.t(:'action_policy.policy.group.member_listing?', name: @namespace.name)
    end

    test 'can add a member to the group' do
      visit group_members_url(@namespace)
      user_to_add = users(:jane_doe)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.add'), count: 1

      click_link I18n.t(:'groups.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.members.new.title')
        find('#member_user_id').find('option', text: user_to_add.email).select_option
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'groups.members.new.add_member_to_group')
      end

      assert_text I18n.t(:'groups.members.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: (@members_count + 1) + header_row_count
      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'can remove a member from the group' do
      visit group_members_url(@namespace)

      group_member = members(:group_one_member_joan_doe)

      table_row = find(:table_row, { 'Username' => group_member.user.email })

      within table_row do
        click_link I18n.t(:'groups.members.index.remove')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.members.destroy.success', user: group_member.user.email)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: (@members_count - 1) + header_row_count
    end

    test 'can remove themselves as a member from the group' do
      visit group_members_url(@namespace)

      table_row = find(:table_row, { 'Username' => @user.email })

      within table_row do
        click_link I18n.t(:'groups.members.index.leave_group')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.members.destroy.leave_success', name: @namespace.name)
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

      Timecop.travel(Time.zone.now + 5) do
        visit group_members_url(namespace)

        assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

        find("#member-#{group_member.id}-access-level-select").find(:xpath, 'option[2]').select_option

        within %(turbo-frame[id="member-update-alert"]) do
          assert_text I18n.t(:'groups.members.update.success', user_email: group_member.user.email)
        end

        group_member_row = find(:table_row, [group_member.user.email])

        within group_member_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
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

    test 'can see the list of namespace group links' do
      namespace_group_link = namespace_group_links(:namespace_group_link6)

      visit group_members_url(namespace_group_link.namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.tabs.groups')

      click_link I18n.t(:'groups.members.index.tabs.groups')

      assert_selector 'th', text: I18n.t(:'groups.group_links.index.table_header.group').upcase

      assert_selector 'tr', count: 4 + header_row_count

      assert_text 'Direct shared', count: 2

      parent_namespace_group_link = namespace_group_link.namespace.parent

      assert_not_nil find(:table_row, { 'Group' => 'Group 4', 'Source' => parent_namespace_group_link.name })
      assert_not_nil find(:table_row, { 'Group' => 'Group 11', 'Source' => parent_namespace_group_link.name })
    end

    test 'can update member expiration' do
      group_member = members(:group_one_member_joan_doe)
      expiry_date = (Time.zone.today + 1).strftime('%Y-%m-%d')

      visit group_members_url(@namespace)

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      find("#group-member-#{group_member.id}-expiration").click.set(expiry_date)
                                                         .native.send_keys(:return)

      within %(turbo-frame[id="member-update-alert"]) do
        assert_text I18n.t(:'groups.members.update.success', user_email: group_member.user.email)
      end

      group_member_row = find(:table_row, [group_member.user.email])

      within group_member_row do
        assert_text 'Updated', count: 1
        assert_text 'less than a minute ago'
      end
    end

    test 'cannot update member expiration' do
      login_as users(:ryan_doe)

      visit group_members_url(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      within('table') do
        assert_selector 'input.datepicker-input', count: 0
      end
    end

    test 'can add a group bot to a group' do
      login_as users(:user30)

      namespace_bot = namespace_bots(:group1_bot0)
      namespace = groups(:user30_group_one)
      members_count = members.select { |member| member.namespace == namespace }.count

      visit group_members_url(namespace)
      user_to_add = namespace_bot.user

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.add'), count: 1

      click_link I18n.t(:'groups.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.members.new.title')
        find('#member_user_id').find('option', text: user_to_add.email).select_option
        find('#member_access_level').find('option',
                                          text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        click_button I18n.t(:'groups.members.new.add_member_to_group')
      end

      assert_text I18n.t(:'groups.members.create.success', user: user_to_add.email)
      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: (members_count + 1) + header_row_count
      assert_not_nil find(:table_row, { 'Username' => user_to_add.email })
    end

    test 'cannot add a project bot to a group' do
      login_as users(:user30)

      namespace_bot = namespace_bots(:project1_bot0)
      namespace = groups(:user30_group_one)

      visit group_members_url(namespace)
      user_to_add = namespace_bot.user

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')

      assert_selector 'a', text: I18n.t(:'groups.members.index.add'), count: 1

      click_link I18n.t(:'groups.members.index.add')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.members.new.title')

        within('#member_user_id') do
          assert_no_selector "option[value='#{user_to_add.email}']"
        end
      end
    end
  end
end
