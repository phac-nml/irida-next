# frozen_string_literal: true

require 'application_system_test_case'

class AdvancedSearchComponentTest < ApplicationSystemTestCase
  test 'default' do
    visit('rails/view_components/advanced_search_component/default')
    within 'span[data-controller-connected="true"]' do
      click_button I18n.t(:'advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 2
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 3
        end
        within all("div[data-advanced-search-target='groupsContainer']")[1] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify removing a condition
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            find('button').click
          end
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 2
        end

        # verify removing a group
        within all("div[data-advanced-search-target='groupsContainer']")[1] do
          click_button I18n.t(:'advanced_search_component.remove_group_button')
        end
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 1

        # verify adding a group
        click_button I18n.t(:'advanced_search_component.add_group_button')
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 2

        # verify adding a condition
        within all("div[data-advanced-search-target='groupsContainer']")[1] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 1
          click_button I18n.t(:'advanced_search_component.add_condition_button')
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 2
        end

        # verify clearing the form
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 1
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify closing the dialog
        first('button').click
      end
      assert_no_selector 'dialog'
    end
  end
end
