# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  def initialize(form:, search:, fields: [], open: false, status: true)
    @form = form
    @search = search
    @fields = field_options(fields)
    @operations = operation_options
    @open = open
    @status = status
  end

  private

  def field_options(fields)
    prefix = 'metadata.'
    metadata_fields, sample_fields = fields.partition { |field| field.start_with?(prefix) }
    sample_field_options = sample_fields.map do |sample_field|
      [I18n.t("samples.table_component.#{sample_field}"), sample_field]
    end
    metadata_field_options = metadata_fields.map do |metadata_field|
      [metadata_field.delete_prefix(prefix), metadata_field]
    end
    {
      I18n.t('advanced_search_component.operation.sample_fields') => sample_field_options,
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
