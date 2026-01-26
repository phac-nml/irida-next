# frozen_string_literal: true

# View component for advanced search functionality.
# This component provides a modal interface for building complex search queries
# with multiple conditions and groups. It supports both entity-specific fields
# and JSONB metadata fields.
class AdvancedSearchComponent < Component
  # Standard operation definitions - maps translation keys to operator values
  STANDARD_OPERATION_KEYS = {
    'equals' => '=',
    'not_equals' => '!=',
    'less_than' => '<=',
    'greater_than' => '>=',
    'contains' => 'contains',
    'does_not_contain' => 'not_contains',
    'exists' => 'exists',
    'not_exists' => 'not_exists',
    'in' => 'in',
    'not_in' => 'not_in'
  }.freeze

  # Enum operation definitions (subset of standard operations)
  ENUM_OPERATION_KEYS = {
    'equals' => '=',
    'not_equals' => '!=',
    'in' => 'in',
    'not_in' => 'not_in'
  }.freeze

  # rubocop:disable Metrics/ParameterLists
  def initialize(form:, search:, entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [],
                 enum_fields: {}, field_label_namespace: 'samples.table_component', open: false, status: true)
    @form = form
    @search = search
    @field_label_namespace = field_label_namespace
    @enum_fields = enum_fields

    # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
    fields = entity_fields.presence || sample_fields
    jsonb = jsonb_fields.presence || metadata_fields

    @entity_fields = entity_field_options(fields)
    @jsonb_fields = jsonb_field_options(jsonb)
    @operations = operation_options
    @enum_operations = enum_operation_options
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
      [translated_field_label(field), field]
    end
  end

  def jsonb_field_options(fields)
    jsonb_options = fields.map do |field|
      # Keep the field label as-is (without translation) but prefix the value with 'metadata.'
      # for JSONB field detection. The Query model strips the 'metadata.' prefix in normalized_field()
      [field, "metadata.#{field}"]
    end
    {
      I18n.t('components.advanced_search_component.operation.metadata_fields') => jsonb_options
    }
  end

  # Build operation options with translated labels
  def operation_options
    build_operation_hash(STANDARD_OPERATION_KEYS)
  end

  # Build enum operation options with translated labels
  def enum_operation_options
    build_operation_hash(ENUM_OPERATION_KEYS)
  end

  # Helper to build operation hash from keys
  def build_operation_hash(operation_keys)
    operation_keys.transform_keys do |key|
      I18n.t("components.advanced_search_component.operation.#{key}")
    end
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

  def translated_field_label(field)
    key = field.to_s
    # Handle array fields where first element is the label
    return field.first if field.is_a?(Array)

    I18n.t(
      "#{@field_label_namespace}.#{key}",
      default: [:"metadata.fields.#{key}", key.tr('.', ' ').humanize]
    )
  rescue I18n::ArgumentError
    key.tr('.', ' ').humanize
  end
end
