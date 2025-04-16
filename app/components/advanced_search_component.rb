# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  def initialize(form:, search:, sample_fields: [], metadata_fields: [], open: false, status: true) # rubocop: disable Metrics/ParameterLists
    @form = form
    @search = search
    @sample_fields = sample_field_options(sample_fields)
    @metadata_fields = metadata_field_options(metadata_fields)
    @operations = operation_options
    @open = open
    @status = status
  end

  private

  def sample_field_options(sample_fields)
    sample_fields.map do |sample_field|
      [I18n.t("samples.table_component.#{sample_field}"), sample_field]
    end
  end

  def metadata_field_options(metadata_fields)
    metadata_field_options = metadata_fields.map do |metadata_field|
      [metadata_field, "metadata.#{metadata_field}"]
    end
    {
      I18n.t('advanced_search_component.operation.metadata_fields') => metadata_field_options
    }
  end

  def operation_options
    {
      I18n.t('advanced_search_component.operation.equals') => '=',
      I18n.t('advanced_search_component.operation.not_equals') => '!=',
      I18n.t('advanced_search_component.operation.less_than') => '<=',
      I18n.t('advanced_search_component.operation.greater_than') => '>=',
      I18n.t('advanced_search_component.operation.contains') => 'contains',
      I18n.t('advanced_search_component.operation.exists') => 'exists',
      I18n.t('advanced_search_component.operation.not_exists') => 'not_exists',
      I18n.t('advanced_search_component.operation.in') => 'in',
      I18n.t('advanced_search_component.operation.not_in') => 'not_in'
    }
  end
end
