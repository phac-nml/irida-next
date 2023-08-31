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

    test 'can see a list of group links' do
      visit group_members_url(@namespace, tab: 'invited_groups')

      assert_selector 'h1', text: I18n.t(:'groups.members.index.title')
      assert_selector 'tr', count: @group_links_count + header_row_count
    end

    test 'cannot access group links' do
      login_as users(:david_doe)

      visit group_members_url(@namespace, tab: 'invited_groups')

      assert_text I18n.t(:'action_policy.policy.group.member_listing?', name: @namespace.name)
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

    test 'can remove a group to group link' do
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      visit group_members_url(@namespace, tab: 'invited_groups')
      assert_selector 'tr', count: @group_links_count + header_row_count

      table_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

      within table_row do
        click_link I18n.t(:'groups.group_links.index.unlink')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.group_links.destroy.success', namespace_name: namespace_group_link.namespace.name,
                                                                group_name: namespace_group_link.group.name)

      assert_selector 'tr', count: (@group_links_count - 1) + header_row_count
    end

    test 'cannot add a group to group link' do
      login_as users(:ryan_doe)
      visit group_members_url(@namespace, tab: 'invited_groups')

      assert_selector 'a', text: I18n.t(:'groups.members.index.invite_group'), count: 0
    end

    test 'can update namespace group links group access level to another access level' do
      namespace_group_link = namespace_group_links(:namespace_group_link5)

      Timecop.travel(Time.zone.now + 5) do
        visit group_members_url(@namespace, tab: 'invited_groups')
        assert_selector 'tr', count: @group_links_count + header_row_count

        find("#invited-group-#{namespace_group_link.group.id}-access-level-select").find(:xpath,
                                                                                         'option[2]').select_option

        within %(turbo-frame[id="invited-group-alert"]) do
          assert_text I18n.t(:'groups.group_links.update.success', namespace_name: namespace_group_link.namespace.name,
                                                                   group_name: namespace_group_link.group.name,
                                                                   param_name: 'group access level')
        end

        namespace_group_link_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

        within namespace_group_link_row do
          assert_text 'Updated', count: 1
          assert_text 'less than a minute ago'
        end
      end
    end

    # test 'can update namespace group links expiration' do
    #   namespace_group_link = namespace_group_links(:namespace_group_link5)

    #   Timecop.travel(Time.zone.now + 5) do
    #     visit group_members_url(@namespace, tab: 'invited_groups')
    #     assert_selector 'tr', count: @group_links_count + header_row_count

    #     find("#invited-#{namespace_group_link.group.id}-expiration").set('2023-08-07')

    #     within %(turbo-frame[id="invited-group-alert"]) do
    #       assert_text I18n.t(:'groups.group_links.update.success', namespace_name: namespace_group_link.namespace.name,
    #                                                                group_name: namespace_group_link.group.name,
    #                                                                param_name: 'expiration')
    #     end

    #     namespace_group_link_row = find(:table_row, { 'Group' => namespace_group_link.group.name })

    #     within namespace_group_link_row do
    #       assert_text 'Updated', count: 1
    #       assert_text 'less than a minute ago'
    #     end
    #   end
    # end
  end
end
