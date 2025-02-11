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
      end
    end
  end

  test 'close dialog prompts for confirmation if filters have not been applied' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'span[data-controller-connected="true"]' do
      click_button I18n.t(:'advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 1
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the dialog has a close button
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"

        # verify that the dialog closes without a confirm dialog if no unapplied filters
        click_button I18n.t('components.dialog.close')
        assert_no_selector 'h1', text: I18n.t(:'advanced_search_component.title')
      end

      click_button I18n.t(:'advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        assert_selector "div[data-advanced-search-target='groupsContainer']", count: 1
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "div[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the dialog has a close button
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"

        # add a new filter
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.age']").select_option
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: '25'
          end
        end

        # verify that the dialog close action prompts a confirm dialog if unapplied filters
        text = dismiss_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'advanced_search_component.confirm_close_text')

        # verify that dismissing the confirm keeps the unapplied filters and dialog open
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            assert_equal 'metadata.age', find("select[name$='[field]']").find("option[value='metadata.age']").value
            assert_equal '>=', find("select[name$='[operator]']").find("option[value='>=']").value
            assert_equal '25', find("input[name$='[value]']").value
          end
        end

        # verify that accepting the confirm discards the unapplied filters and closes the dialog
        text = accept_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'advanced_search_component.confirm_close_text')
        assert_no_selector 'h1', text: I18n.t(:'advanced_search_component.title')
      end
    end
  end
end
