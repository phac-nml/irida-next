# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class GroupsTest < ApplicationSystemTestCase
    def setup
      login_as users(:alph_abet)
    end

    test 'can see the list of groups' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'components.pagination.next')
      assert_text I18n.t(:'components.pagination.previous')
      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 6
        [*('f'..'a')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'components.pagination.previous')
      assert_text I18n.t(:'components.pagination.next')
      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end
    end

    test 'can sort the list of groups by name descending' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.name_desc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.name_desc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can sort the list of groups by name ascending' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.name_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.name_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_a).name
      end
    end

    test 'can sort the list of groups by updated at desc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.updated_at_desc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.updated_at_desc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_a).name
      end
    end

    test 'can sort the list of groups by updated at asc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.updated_at_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.updated_at_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can sort the list of groups by created_at asc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.created_at_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can expand parent groups to see their children' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      within 'ul.groups-list.namespace-list-tree' do
        within :xpath, "li[contains(@class, 'namespace-entry')][.//*/a[text()='#{groups(:group_one).name}']]" do
          assert_text groups(:group_one).name
          assert_no_selector 'ul.groups-list.namespace-list-tree'
          find('a.folder-toggle-wrap').click
        end
      end

      within('ul.groups-list.namespace-list-tree:first-child > li:first-child') do
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
