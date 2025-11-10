# frozen_string_literal: true

# View component for advanced search functionality.
# This component provides a modal interface for building complex search queries
# with multiple conditions and groups. It supports both entity-specific fields
# and JSONB metadata fields.
class AdvancedSearchComponent < Component
  # rubocop:disable Metrics/ParameterLists
  def initialize(form:, search:, entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [],
                 field_label_namespace: 'samples.table_component', open: false, status: true)
    @form = form
    @search = search
    @field_label_namespace = field_label_namespace

    # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
    fields = entity_fields.presence || sample_fields
    jsonb = jsonb_fields.presence || metadata_fields

    @entity_fields = entity_field_options(fields)
    @jsonb_fields = jsonb_field_options(jsonb)
    @operations = operation_options
    @open = open
    @status = status

    # Determine the search model classes based on the search object
    @search_group_class = search_class_map(search.class.name, :group)
    @search_condition_class = search_class_map(search.class.name, :condition)
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def entity_field_options(fields)
    fields.map do |field|
      [I18n.t("#{@field_label_namespace}.#{field}"), field]
    end
  end

  def jsonb_field_options(fields)
    jsonb_options = fields.map do |field|
      [field, "metadata.#{field}"]
    end
    {
      I18n.t('components.advanced_search_component.operation.metadata_fields') => jsonb_options
    }
  end

  def operation_options
    {
      I18n.t('components.advanced_search_component.operation.equals') => '=',
      I18n.t('components.advanced_search_component.operation.not_equals') => '!=',
      I18n.t('components.advanced_search_component.operation.less_than') => '<=',
      I18n.t('components.advanced_search_component.operation.greater_than') => '>=',
      I18n.t('components.advanced_search_component.operation.contains') => 'contains',
      I18n.t('components.advanced_search_component.operation.exists') => 'exists',
      I18n.t('components.advanced_search_component.operation.not_exists') => 'not_exists',
      I18n.t('components.advanced_search_component.operation.in') => 'in',
      I18n.t('components.advanced_search_component.operation.not_in') => 'not_in'
    }
  end

  def search_class_map(query_class_name, type)
    class_mappings = {
      'Sample::Query' => {
        group: Sample::SearchGroup,
        condition: Sample::SearchCondition
      },
      'WorkflowExecution::Query' => {
        group: WorkflowExecution::SearchGroup,
        condition: WorkflowExecution::SearchCondition
      }
    }

    # Default to Sample classes for backward compatibility
    class_mappings.fetch(query_class_name, class_mappings['Sample::Query'])[type]
  end
end
