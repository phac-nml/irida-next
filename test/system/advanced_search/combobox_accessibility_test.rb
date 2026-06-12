# frozen_string_literal: true

require 'application_system_test_case'

module AdvancedSearch
  class ComboboxAccessibilityTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      Flipper.enable(:advanced_search_with_auto_complete, @user)
    end

    test 'group samples field combobox passes axe and updates operator options' do
      visit group_samples_url(groups(:group_one))
      open_advanced_search_dialog

      within_first_field_combobox do
        combobox = find("input[role='combobox']")
        assert_no_selector 'input[role="combobox"][aria-label]'
        assert_selector 'input[role="combobox"][aria-required="true"]'

        assert_combobox_passes_axe_in_required_states(
          combobox: combobox,
          filter_text: I18n.t('samples.table_component.puid')
        )
      end

      within 'dialog' do
        within first("select[name$='[operator]']") do
          assert_text I18n.t('components.advanced_search_component.v1.operation.in')
          assert_text I18n.t('components.advanced_search_component.v1.operation.not_in')
        end
      end
    end

    test 'group samples invalid field combobox passes axe' do
      visit group_samples_url(groups(:group_one))
      open_advanced_search_dialog
      assert_invalid_field_combobox_passes_axe
    end

    test 'workflow executions field combobox passes axe and updates operator options' do
      Flipper.enable(:workflow_execution_advanced_search)

      visit workflow_executions_path
      open_advanced_search_dialog

      within_first_field_combobox do
        combobox = find("input[role='combobox']")
        assert_combobox_passes_axe_in_required_states(
          combobox: combobox,
          filter_text: I18n.t('workflow_executions.table_component.state')
        )
      end

      within 'dialog' do
        within first("select[name$='[operator]']") do
          allowed_operators = all("option:not([hidden]):not([value=''])").map(&:value)
          assert_equal %w[= != in not_in], allowed_operators
        end

        first("select[name$='[operator]']").find("option[value='=']").select_option
        assert_selector "select[name$='[value]']"
      end
    ensure
      Flipper.disable(:workflow_execution_advanced_search)
    end

    test 'advanced search uses native field select when autocomplete flag is disabled' do
      Flipper.disable(:advanced_search_with_auto_complete, @user)

      visit group_samples_url(groups(:group_one))
      open_advanced_search_dialog

      within 'dialog' do
        assert_selector "select[name$='[field]']"
        assert_no_selector "input[role='combobox']"
      end
    ensure
      Flipper.enable(:advanced_search_with_auto_complete, @user)
    end
  end
end
