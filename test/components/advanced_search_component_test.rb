# frozen_string_literal: true

require 'application_system_test_case'

class AdvancedSearchComponentTest < ApplicationSystemTestCase
  test 'default' do
    visit('rails/view_components/advanced_search_component/default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 3
        end
        within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the field list & option group elements are localized
        first("input[role='combobox']").fill_in with: ''
        first("input[role='combobox']").click
        within first("div[role='listbox']") do
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.name'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.puid'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.created_at'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.updated_at'), count: 2
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.attachments_updated_at'), count: 1
          assert_selector "div[role='presentation']",
                          text: I18n.t('components.advanced_search_component.operation.metadata_fields'),
                          count: 1
        end

        # verify the operator list is localized
        within first("select[name$='[operator]']") do
          assert_text I18n.t('components.advanced_search_component.operation.equals')
          assert_text I18n.t('components.advanced_search_component.operation.not_equals')
          assert_text I18n.t('components.advanced_search_component.operation.less_than')
          assert_text I18n.t('components.advanced_search_component.operation.greater_than')
          assert_text I18n.t('components.advanced_search_component.operation.contains')
          assert_text I18n.t('components.advanced_search_component.operation.exists')
          assert_text I18n.t('components.advanced_search_component.operation.not_exists')
          assert_text I18n.t('components.advanced_search_component.operation.in')
          assert_text I18n.t('components.advanced_search_component.operation.not_in')
        end

        # verify removing a condition
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find('button').click
          end
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        end

        # verify removing a group
        within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
          click_button I18n.t(:'components.advanced_search_component.remove_group_button')
        end
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1

        # verify adding a group
        click_button I18n.t(:'components.advanced_search_component.add_group_button')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2

        # verify adding a condition
        within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
          click_button I18n.t(:'components.advanced_search_component.add_condition_button')
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2
        end

        # verify clearing the form
        click_button I18n.t(:'components.advanced_search_component.clear_filter_button')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        end
      end
    end
  end

  test 'close dialog prompts for confirmation if filters have not been applied' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the dialog has a close button
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"

        # verify that the dialog closes without a confirm dialog if no unapplied filters
        click_button I18n.t('components.dialog.close')
        assert_no_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the dialog has a close button
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"

        # add a new filter
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'age'
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: '25'
          end
        end

        # verify that the dialog close action prompts a confirm dialog if unapplied filters
        text = dismiss_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'components.advanced_search_component.confirm_close_text')

        # verify that dismissing the confirm keeps the unapplied filters and dialog open
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            assert_equal 'age', find("input[id$='field']").value
            assert_equal '>=', find("select[name$='[operator]']").find("option[value='>=']").value
            assert_equal '25', find("input[name$='[value]']").value
          end
        end

        # verify that accepting the confirm discards the unapplied filters and closes the dialog
        text = accept_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'components.advanced_search_component.confirm_close_text')
        assert_no_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        # verify accessibility
        assert_accessible

        # verify the form is pre-populated
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        end

        # verify the dialog has a close button
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"

        # select a value for field
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'age'
          end
        end

        # verify that the dialog close action prompts a confirm dialog if unapplied filters
        text = dismiss_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'components.advanced_search_component.confirm_close_text')

        # verify that dismissing the confirm keeps the unapplied filters and dialog open
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            assert_equal 'age', find("input[id$='field']").value
          end
        end

        # verify that accepting the confirm discards the unapplied filters and closes the dialog
        text = accept_confirm do
          click_button I18n.t('components.dialog.close')
        end
        assert_includes text, I18n.t(:'components.advanced_search_component.confirm_close_text')
        assert_no_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      end
    end
  end
end
