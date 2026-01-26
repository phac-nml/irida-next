# frozen_string_literal: true

# View component for advanced search functionality.
#
# Provides a modal interface for building complex search queries with multiple
# conditions and groups. Supports both entity-specific fields and JSONB metadata fields.
#
# @example Basic usage with workflow executions
#   render AdvancedSearchComponent.new(
#     form: f,
#     search: @query,
#     entity_fields: %w[id name state],
#     enum_fields: { 'state' => { values: ['running', 'completed'], labels: nil } }
#   )
#
# @example Usage with samples (legacy parameter names still supported)
#   render AdvancedSearchComponent.new(
#     form: f,
#     search: @query,
#     sample_fields: @sample_fields,
#     metadata_fields: @metadata_fields
#   )
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

  # Enum operation definitions (subset of standard operations for enum/select fields)
  ENUM_OPERATION_KEYS = {
    'equals' => '=',
    'not_equals' => '!=',
    'in' => 'in',
    'not_in' => 'not_in'
  }.freeze

  # Initializes the advanced search component.
  #
  # @param form [ActionView::Helpers::FormBuilder] the form builder instance
  # @param search [AdvancedSearchQueryForm] the search query object (e.g., Sample::Query, WorkflowExecution::Query)
  # @param entity_fields [Array<String>] list of searchable entity field names
  # @param jsonb_fields [Array<String>] list of searchable JSONB/metadata field names
  # @param sample_fields [Array<String>] deprecated, use entity_fields instead
  # @param metadata_fields [Array<String>] deprecated, use jsonb_fields instead
  # @param enum_fields [Hash{String => Hash}] configuration for enum/select fields
  #   @option enum_fields [Array<String>] :values the valid enum values
  #   @option enum_fields [Hash, nil] :labels optional hash mapping values to display labels
  #   @option enum_fields [String, nil] :translation_key I18n key prefix for translating values
  # @param field_label_namespace [String] I18n namespace for field label translations
  # @param open [Boolean] whether the dialog should be open initially
  # @param status [Boolean] whether the filter is currently active
  # rubocop:disable Metrics/ParameterLists
  def initialize(form:, search:, entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [],
                 enum_fields: {}, field_label_namespace: 'samples.table_component', open: false, status: true)
    @form = form
    @search = search
    @field_label_namespace = field_label_namespace
    @enum_fields = enum_fields

    # Emit deprecation warnings for legacy parameter names
    deprecate_legacy_params(sample_fields, metadata_fields)

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

  # Converts entity field names to select options with translated labels.
  #
  # @param fields [Array<String>] list of field names
  # @return [Array<Array(String, String)>] array of [label, value] pairs
  def entity_field_options(fields)
    fields.map do |field|
      [translated_field_label(field), field]
    end
  end

  # Converts JSONB field names to grouped select options.
  #
  # @param fields [Array<String>] list of JSONB field names
  # @return [Hash{String => Array}] grouped options hash for grouped_options_for_select
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

  # Builds standard operation options with translated labels.
  #
  # @return [Hash{String => String}] hash mapping translated labels to operator values
  def operation_options
    build_operation_hash(STANDARD_OPERATION_KEYS)
  end

  # Builds enum-specific operation options with translated labels.
  #
  # @return [Hash{String => String}] hash mapping translated labels to operator values
  def enum_operation_options
    build_operation_hash(ENUM_OPERATION_KEYS)
  end

  # Transforms operation keys hash by translating the keys.
  #
  # @param operation_keys [Hash{String => String}] hash with translation keys as keys
  # @return [Hash{String => String}] hash with translated strings as keys
  def build_operation_hash(operation_keys)
    operation_keys.transform_keys do |key|
      I18n.t("components.advanced_search_component.operation.#{key}")
    end
  end

  # Resolves the search group and condition classes based on the query class.
  #
  # Uses convention-based resolution: extracts the namespace from the query class
  # and constructs the corresponding SearchGroup or SearchCondition class name.
  #
  # @example
  #   resolve_search_class('Sample::Query', :group)           # => Sample::SearchGroup
  #   resolve_search_class('WorkflowExecution::Query', :condition) # => WorkflowExecution::SearchCondition
  #
  # @param query_class_name [String] the full class name of the query (e.g., 'Sample::Query')
  # @param type [Symbol] either :group or :condition
  # @return [Class] the corresponding SearchGroup or SearchCondition class
  # @raise [NameError] if the resolved class doesn't exist
  def search_class_map(query_class_name, type)
    # Extract namespace (e.g., 'Sample' from 'Sample::Query')
    namespace = query_class_name.deconstantize

    # Build class name based on type (e.g., 'Sample::SearchGroup')
    class_suffix = type == :group ? 'SearchGroup' : 'SearchCondition'
    class_name = "#{namespace}::#{class_suffix}"

    class_name.constantize
  rescue NameError
    # Fall back to Sample classes for backward compatibility
    type == :group ? Sample::SearchGroup : Sample::SearchCondition
  end

  # Emits deprecation warnings for legacy parameter names.
  #
  # @param sample_fields [Array] the deprecated sample_fields parameter
  # @param metadata_fields [Array] the deprecated metadata_fields parameter
  def deprecate_legacy_params(sample_fields, metadata_fields)
    if sample_fields.present?
      Rails.logger.warn(
        '[DEPRECATION] AdvancedSearchComponent: sample_fields is deprecated, use entity_fields instead'
      )
    end

    return if metadata_fields.blank?

    Rails.logger.warn(
      '[DEPRECATION] AdvancedSearchComponent: metadata_fields is deprecated, use jsonb_fields instead'
    )
  end

  # Translates a field name to a human-readable label.
  #
  # @param field [String, Array] the field name or [label, value] array
  # @return [String] the translated or humanized field label
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
