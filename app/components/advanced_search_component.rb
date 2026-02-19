# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  # @param sample_fields [Array] @deprecated Use fields: instead
  # @param metadata_fields [Array] @deprecated Use fields: instead
  # rubocop:disable Metrics/ParameterLists
  def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [], open: false, status: true,
                 search_group_class: nil, search_condition_class: nil)
    @form = form
    @search = search
    @fields = normalized_fields(fields:, sample_fields:, metadata_fields:)
    @operations = operation_options
    @open = open
    @status = status
    @search_group_class = search_group_class || infer_search_group_class
    @search_condition_class = search_condition_class || infer_search_condition_class
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def normalized_fields(fields:, sample_fields:, metadata_fields:)
    return fields.symbolize_keys if fields.present?

    AdvancedSearch::Fields.for_samples(sample_fields:, metadata_fields:)
  end

  def infer_search_group_class
    @search.groups.first&.class || raise(
      ArgumentError,
      'search_group_class is required when search has no groups'
    )
  end

  def infer_search_condition_class
    return @search_group_class.condition_class if @search_group_class.respond_to?(:condition_class)

    first_group = @search.groups.first
    first_condition = first_group&.conditions&.first

    first_condition&.class || raise(
      ArgumentError,
      'search_condition_class is required when group class does not define .condition_class'
    )
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
