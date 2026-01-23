# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  # rubocop:disable Metrics/ParameterLists
  def initialize(
    form:,
    search:,
    sample_fields: [],
    metadata_fields: [],
    open: false,
    status: true,
    i18n_prefix: 'samples.table_component',
    search_group_class: Sample::SearchGroup,
    search_condition_class: Sample::SearchCondition,
    enum_fields: {}
  )
    @form = form
    @search = search
    @sample_fields = sample_field_options(sample_fields, i18n_prefix)
    @metadata_fields = metadata_field_options(metadata_fields)
    @operations = operation_options
    @open = open
    @status = status
    @i18n_prefix = i18n_prefix
    @search_group_class = search_group_class
    @search_condition_class = search_condition_class
    @enum_fields = enum_fields
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def sample_field_options(sample_fields, i18n_prefix)
    sample_fields.map do |sample_field|
      [I18n.t("#{i18n_prefix}.#{sample_field}"), sample_field]
    end
  end

  def metadata_field_options(metadata_fields)
    metadata_field_options = metadata_fields.map do |metadata_field|
      [metadata_field, "metadata.#{metadata_field}"]
    end
    {
      I18n.t('components.advanced_search_component.operation.metadata_fields') => metadata_field_options
    }
  end

  def operation_options
    {
      I18n.t('components.advanced_search_component.operation.equals') => '=',
      I18n.t('components.advanced_search_component.operation.not_equals') => '!=',
      I18n.t('components.advanced_search_component.operation.less_than') => '<=',
      I18n.t('components.advanced_search_component.operation.greater_than') => '>=',
      I18n.t('components.advanced_search_component.operation.contains') => 'contains',
      I18n.t('components.advanced_search_component.operation.does_not_contain') => 'not_contains',
      I18n.t('components.advanced_search_component.operation.exists') => 'exists',
      I18n.t('components.advanced_search_component.operation.not_exists') => 'not_exists',
      I18n.t('components.advanced_search_component.operation.in') => 'in',
      I18n.t('components.advanced_search_component.operation.not_in') => 'not_in'
    }
  end
end
