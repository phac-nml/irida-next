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
end
