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
end
