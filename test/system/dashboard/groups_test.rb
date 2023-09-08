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
        assert_selector 'li', count: 6
        assert_text groups(:group_one).name
        assert_text groups(:group_two).name
        assert_text groups(:group_three).name
        assert_text groups(:group_five).name
        assert_text groups(:group_six).name
      end
    end

    test 'can expand parent groups to see their children' do
      visit dashboard_groups_url

      within 'ul.groups-list.group-list-tree' do
        within first('li') do
          assert_text groups(:group_one).name
          assert_no_selector 'ul.groups-list.group-list-tree'
          find('a.folder-toggle-wrap').click
        end
      end

      within first('ul.groups-list.group-list-tree') do
        assert_text groups(:group_one).name
        assert_text groups(:subgroup1).name
      end
    end

    test 'can create a group from listing page' do
      visit dashboard_groups_url

      click_link I18n.t(:'dashboard.groups.index.create_group_button')

      within %(div[data-controller="slugify"][data-controller-connected="true"]) do
        fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'New group'

        assert_selector %(input[data-slugify-target="path"]) do |input|
          assert_equal 'new-group', input['value']
        end

        fill_in 'Description', with: 'New group description'
        click_on I18n.t(:'groups.create.submit')
      end

      assert_text I18n.t(:'groups.create.success')
      assert_selector 'h1', text: 'New group'
    end
  end
end
