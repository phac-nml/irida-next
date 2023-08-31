# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class GroupsTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
    end

    test 'can see the list of groups' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.group-list-tree' do
        assert_selector 'li', count: 5
        assert_text groups(:group_one).human_name
        assert_text groups(:group_two).human_name
        assert_text groups(:group_three).human_name
        assert_text groups(:group_five).human_name
        assert_text groups(:group_six).human_name
      end
    end

    test 'can expand parent groups to see their children' do
      visit dashboard_groups_url

      within 'ul.groups-list.group-list-tree' do
        within first('li') do
          assert_text groups(:group_one).human_name
          assert_no_selector 'ul.groups-list.group-list-tree'
          find('a.folder-toggle-wrap').click
          assert_selector 'ul.groups-list.group-list-tree'
        end
      end
    end
  end
end
