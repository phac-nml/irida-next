# frozen_string_literal: true

# Shared assertions for the samples table rendered in integration tests.
module SamplesTableHelper
  SAMPLES_TABLE_COLUMNS = %w[puid name created_at updated_at attachments_updated_at].freeze

  def assert_samples_table_headers(locale: I18n.locale)
    assert_select 'table thead' do
      SAMPLES_TABLE_COLUMNS.each do |column|
        assert_select 'th a', text: /#{Regexp.escape(I18n.t("samples.table_component.#{column}", locale:))}/i
      end
    end
  end

  def assert_samples_data_grid(locale: I18n.locale)
    assert_select '#samples-table.samples-data-grid.pvc-data-grid.pvc-data-grid--fill'
    assert_select '#samples-table table[role="grid"]'
    assert_select 'th[data-sticky-cell]', text: /#{Regexp.escape(I18n.t('samples.table_component.puid', locale:))}/i
    assert_select 'th[data-sticky-cell]', text: /#{Regexp.escape(I18n.t('samples.table_component.name', locale:))}/i
  end

  def assert_actions_dropdown(present:, locale: I18n.locale)
    label = I18n.t('shared.samples.actions_dropdown.label', locale:)
    if present
      assert_select 'button[aria-label=?]', label
    else
      assert_select 'button[aria-label=?]', label, count: 0
    end
  end

  def assert_actions_menu_item(key, present:, locale: I18n.locale)
    text = /#{Regexp.escape(I18n.t("shared.samples.actions_dropdown.#{key}", locale:))}/
    if present
      assert_select 'button[role="menuitem"]', text:
    else
      assert_select 'button[role="menuitem"]', text:, count: 0
    end
  end

  def assert_workflow_execution_link(present:, locale: I18n.locale)
    text = /#{Regexp.escape(I18n.t('projects.samples.index.workflows.button_sr', locale:))}/
    if present
      assert_select 'span', text:
    else
      assert_select 'span', text:, count: 0
    end
  end

  def assert_selection_controls(sample, present:)
    if present
      assert_select '#samples-table[data-controller~=?]', 'selection'
      assert_select 'button#select-all-button'
      assert_select 'button#deselect-all-button'
      assert_select 'form#select-all-form'
      assert_select 'form#deselect-all-form'
      assert_select 'input#select-page[data-selection-target=?]', 'selectPage'
      assert_select "input##{dom_id(sample, :checkbox)}[data-selection-target=?]", 'rowSelection'
    else
      assert_select 'button#select-all-button', count: 0
      assert_select 'button#deselect-all-button', count: 0
      assert_select 'input#select-page', count: 0
      assert_select "input##{dom_id(sample, :checkbox)}", count: 0
    end
  end
end
