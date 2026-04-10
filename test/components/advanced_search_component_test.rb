# frozen_string_literal: true

require 'application_system_test_case'

class AdvancedSearchComponentTest < ApplicationSystemTestCase
  def setup
    Flipper.enable(:advanced_search_with_auto_complete)
  end

  test 'default' do
    visit('rails/view_components/advanced_search_component/default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        assert_accessible

        assert_selector "fieldset[data-advanced-search--v1-target='groupsContainer']", count: 2
        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 3
        end
        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[1] do
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 1
        end

        within first("div[data-controller='combobox--v1']") do
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

        within first("select[name$='[operator]']") do
          assert_text I18n.t('components.advanced_search_component.v1.operation.equals')
          assert_text I18n.t('components.advanced_search_component.v1.operation.not_equals')
          assert_text I18n.t('components.advanced_search_component.v1.operation.less_than')
          assert_text I18n.t('components.advanced_search_component.v1.operation.greater_than')
          assert_text I18n.t('components.advanced_search_component.v1.operation.contains')
          assert_text I18n.t('components.advanced_search_component.v1.operation.does_not_contain')
          assert_text I18n.t('components.advanced_search_component.v1.operation.exists')
          assert_text I18n.t('components.advanced_search_component.v1.operation.not_exists')
          assert_text I18n.t('components.advanced_search_component.v1.operation.in')
          assert_text I18n.t('components.advanced_search_component.v1.operation.not_in')
        end

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            find('button').click
          end
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 2
        end

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[1] do
          click_button I18n.t(:'components.advanced_search_component.v1.remove_group_button')
        end
        assert_selector "fieldset[data-advanced-search--v1-target='groupsContainer']", count: 1

        click_button I18n.t(:'components.advanced_search_component.v1.add_group_button')
        assert_selector "fieldset[data-advanced-search--v1-target='groupsContainer']", count: 2

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[1] do
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 1
          click_button I18n.t(:'components.advanced_search_component.v1.add_condition_button')
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 2
        end
      end
    end
  end

  test 'close dialog clears form and closes when there is no active search' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        assert_accessible
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.v1.title')
        assert_selector ".dialog--header button[aria-label='#{I18n.t('components.dialog.close')}']"
        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'age'
            find("select[name$='[operator]']").find("option[value='>=']").select_option
            find("input[name$='[value]']").fill_in with: '25'
          end
        end

        click_button I18n.t('components.dialog.close')
      end
      assert_no_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')

      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        assert_accessible
        assert_selector "fieldset[data-advanced-search--v1-target='groupsContainer']", count: 1
        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 1
          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            assert_equal '', find("input[id$='field']").value
            assert_equal '', find("select[name$='[operator]']").value
            assert_equal '', find("input[name$='[value]']", visible: :all).value
          end
        end
      end
    end
  end

  test 'close dialog restores applied state when active search exists' do
    visit('rails/view_components/advanced_search_component/default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            find("select[name$='[operator]']").find("option[value='contains']").select_option
            find("input[name$='[value]']", visible: :visible).fill_in with: 'United States'
          end

          click_button I18n.t(:'components.advanced_search_component.v1.add_condition_button')
        end

        accept_confirm do
          click_button I18n.t('components.dialog.close')
        end
      end

      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        assert_selector "fieldset[data-advanced-search--v1-target='groupsContainer']", count: 2

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", count: 3

          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            assert_equal '=', find("select[name$='[operator]']", visible: :visible).value
            assert_equal 'Canada', find("input[name$='[value]']", visible: :visible).value
          end
        end
      end
    end
  end

  test 'apply filter requires at least one complete condition' do
    visit('rails/view_components/advanced_search_component/empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
        assert_selector "div[data-advanced-search--v1-target='submitError']",
                        text: I18n.t(:'components.advanced_search_component.v1.minimum_condition_error')

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']")[0] do
            find("input[id$='field']").fill_in with: 'name'
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: 'Sample 1'
          end
        end

        assert_no_selector "div[data-advanced-search--v1-target='submitError']",
                           text: I18n.t(:'components.advanced_search_component.v1.minimum_condition_error')
      end
    end
  end

  test 'workflow preview renders model-specific fields without sample coupling' do
    visit('rails/view_components/advanced_search_component/workflow')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        assert_accessible

        within first("div[data-controller='combobox--v1']") do
          combobox = find("input[role='combobox']")
          combobox.click
          combobox.send_keys([:ctrl, 'a'], :delete)

          assert_selector "div[role='option']",
                          text: /\A#{Regexp.escape(I18n.t('workflow_executions.table_component.id'))}\z/,
                          count: 1
          assert_selector "div[role='option']",
                          text: /\A#{Regexp.escape(I18n.t('workflow_executions.table_component.run_id'))}\z/,
                          count: 1
          assert_selector "div[role='option']",
                          text: /\A#{Regexp.escape(I18n.t('workflow_executions.table_component.state'))}\z/,
                          count: 1
          assert_selector "div[role='option']",
                          text: /\A#{Regexp.escape(I18n.t('workflow_executions.table_component.workflow_name'))}\z/,
                          count: 1

          combobox.send_keys(I18n.t('workflow_executions.table_component.state'), :enter)
        end

        within first("select[name$='[operator]']") do
          allowed_operators = all("option:not([hidden]):not([value=''])").map(&:value)
          assert_equal %w[= != in not_in], allowed_operators
        end

        first("select[name$='[operator]']").find("option[value='=']").select_option
        assert_selector "select[name$='[value]']"
      end
    end
  end

  test 'workflow preview keeps enum operators available with native field selects' do
    Flipper.disable(:advanced_search_with_auto_complete)

    visit('rails/view_components/advanced_search_component/workflow')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        first("select[name$='[field]']").find("option[value='state']").select_option

        within first("select[name$='[operator]']") do
          allowed_operators = all("option:not([hidden]):not([value=''])").map(&:value)
          assert_equal %w[= != in not_in], allowed_operators
        end

        first("select[name$='[operator]']").find("option[value='not_in']").select_option
        assert_selector "select[name$='[value][]']"
      end
    end
  ensure
    Flipper.enable(:advanced_search_with_auto_complete)
  end

  test 'dynamic condition changes preserve groups_attributes payload naming' do
    visit('rails/view_components/advanced_search_component/default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v1.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      within 'dialog' do
        click_button I18n.t(:'components.advanced_search_component.v1.add_group_button')

        within all("fieldset[data-advanced-search--v1-target='groupsContainer']").last do
          click_button I18n.t(:'components.advanced_search_component.v1.add_condition_button')
          assert_selector :xpath,
                          "//*[@name='q[groups_attributes][2][conditions_attributes][0][field]']",
                          visible: :all
          assert_selector :xpath,
                          "//*[@name='q[groups_attributes][2][conditions_attributes][1][field]']",
                          visible: :all

          within all("fieldset[data-advanced-search--v1-target='conditionsContainer']").first do
            find('button').click
          end

          assert_selector :xpath,
                          "//*[@name='q[groups_attributes][2][conditions_attributes][0][field]']",
                          visible: :all
          assert_no_selector :xpath,
                             "//*[@name='q[groups_attributes][2][conditions_attributes][1][field]']",
                             visible: :all
        end
      end
    end
  end
end
