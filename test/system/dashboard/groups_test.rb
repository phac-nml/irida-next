# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class GroupsTest < ApplicationSystemTestCase
    def setup
      login_as users(:alph_abet)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @subgroup12b = groups(:subgroup_twelve_b)
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

      click_on I18n.t(:'viral.pagy.pagination_component.next')
      assert_text I18n.t(:'viral.pagy.pagination_component.previous')
      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 6
        [*('f'..'a')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'viral.pagy.pagination_component.previous')
      assert_text I18n.t(:'viral.pagy.pagination_component.next')
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
      group1 = groups(:group_one)
      subgroup1 = groups(:subgroup1)
      visit dashboard_groups_url

      within("li#group_#{group1.id}") do
        assert_text group1.name
        assert_no_selector 'ul.groups-list.namespace-list-tree'
        assert_no_text subgroup1.name
        find('a.folder-toggle-wrap').click
      end

      within("li#group_#{group1.id}") do
        assert_text group1.name
        assert_text subgroup1.name
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

    test 'can search for a group by name or puid' do
      visit dashboard_groups_url

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'group a'
      find('input.t-search-component').native.send_keys(:return)

      assert_text groups(:group_a).name
      assert_no_text groups(:group_b).name

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: groups(:group_b).puid
      find('input.t-search-component').native.send_keys(:return)

      assert_no_text groups(:group_a).name
      assert_text groups(:group_b).name

      #   Test empty state
      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'z6z6z6'
      find('input.t-search-component').native.send_keys(:return)
      assert_text I18n.t(:'dashboard.groups.index.no_groups_description')
    end

    test 'filtering renders flat list' do
      group1 = groups(:group_one)
      group3 = groups(:group_three)
      login_as users(:john_doe)
      visit dashboard_groups_url

      within('#groups_tree') do
        within("#group_#{group1.id}") do
          assert_text group1.name
          assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
        end

        within("#group_#{group3.id}") do
          assert_text group3.name
          assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
        end
      end

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'group'
      find('input.t-search-component').native.send_keys(:return)

      within('#groups_tree') do
        assert_text group1.name
        assert_text group3.name
        assert_no_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end
    end

    test 'should display a samples count that includes samples from shared groups and projects' do
      login_as users(:john_doe)
      visit dashboard_groups_url
      group = groups(:group_three)

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 3, group.aggregated_samples_count

      within("#group_#{group.id}-samples-count") do
        assert_text group.aggregated_samples_count
      end
    end
  end
end
