# frozen_string_literal: true

module AdvancedSearchComboboxTestHelper
  ADVANCED_SEARCH_DIALOG_SELECTOR = '#advanced-search-dialog'

  def visit_for_advanced_search_combobox_test(path)
    page.visit(path)
  end

  def open_advanced_search_dialog
    click_button I18n.t(:'components.advanced_search_component.v1.title')
    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
  end

  def within_first_field_combobox(&)
    within page.find('dialog') do
      within first("div[data-controller='combobox--v1']", &)
    end
  end

  def assert_combobox_passes_axe_in_required_states(combobox:, filter_text:)
    assert_accessible(within: ADVANCED_SEARCH_DIALOG_SELECTOR)

    combobox.click
    assert_accessible(within: ADVANCED_SEARCH_DIALOG_SELECTOR)

    combobox.send_keys([:ctrl, 'a'], :delete, filter_text)
    assert_accessible(within: ADVANCED_SEARCH_DIALOG_SELECTOR)

    combobox.send_keys(:enter)
    assert_accessible(within: ADVANCED_SEARCH_DIALOG_SELECTOR)
  end

  def assert_invalid_field_combobox_passes_axe
    click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')

    within page.find('dialog') do
      assert_selector 'input[role="combobox"][aria-invalid="true"]'
    end

    assert_accessible(within: ADVANCED_SEARCH_DIALOG_SELECTOR)
  end
end
