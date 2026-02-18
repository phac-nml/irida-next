# frozen_string_literal: true

require 'application_system_test_case'

class AdvancedSearchComponentTest < ApplicationSystemTestCase
  def setup
    Flipper.enable(:advanced_search_with_auto_complete)
  end

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
        within first("div[data-controller='select-with-auto-complete']") do
          combobox = find("input[role='combobox']")
          combobox.click
          combobox.send_keys([:ctrl, 'a'], :delete)
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.name'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.puid'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.created_at'), count: 1
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.updated_at'), count: 2
          assert_selector "div[role='option']", text: I18n.t('samples.table_component.attachments_updated_at'),
                                                count: 1
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
          assert_text I18n.t('components.advanced_search_component.operation.does_not_contain')
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
      end
    end
  end

  test 'close dialog clears form and closes when there is no active search' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        assert_accessible
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'age'
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: '25'
          end
        end

        click_button I18n.t('components.dialog.close')
      end
      assert_no_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')

      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        assert_accessible
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            assert_equal '', find("input[id$='field']").value
            assert_equal '', find("select[name$='[operator]']").value
            assert_equal '', find("input[name$='[value]']", visible: :all).value
          end
        end
      end
    end
  end

  test 'apply filter requires at least one complete condition' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.title')
      within 'dialog' do
        click_button I18n.t(:'components.advanced_search_component.apply_filter_button')
        assert_selector "div[data-advanced-search-target='submitError']",
                        text: I18n.t(:'components.advanced_search_component.minimum_condition_error')

        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'name'
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: 'Sample 1'
          end
        end

        assert_no_selector "div[data-advanced-search-target='submitError']",
                           text: I18n.t(:'components.advanced_search_component.minimum_condition_error')
      end
    end
  end
end
