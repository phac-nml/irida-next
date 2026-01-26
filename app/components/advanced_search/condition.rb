# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition.
  #
  # A condition consists of three parts: field selector, operator selector, and value input.
  # The available operators change based on whether the selected field is an enum field.
  #
  # @example Rendering a condition
  #   render AdvancedSearch::Condition.new(
  #     groups_form: groups_form,
  #     group_index: 0,
  #     condition: condition,
  #     condition_index: 0,
  #     condition_number: 1,
  #     entity_fields: [['Name', 'name'], ['State', 'state']],
  #     enum_fields: { 'state' => { values: %w[running completed] } },
  #     operations: standard_operations,
  #     enum_operations: enum_operations
  #   )
  class Condition < Component
    # Initializes the condition component.
    #
    # @param groups_form [ActionView::Helpers::FormBuilder] the nested form builder for groups
    # @param group_index [Integer, String] the index of the parent group
    # @param condition [SearchCondition] the condition model object
    # @param condition_index [Integer, String] the index of this condition within the group
    # @param condition_number [Integer] the display number for the condition legend (1-based)
    # @param entity_fields [Array] select options for entity fields
    # @param jsonb_fields [Hash] grouped select options for JSONB/metadata fields
    # @param sample_fields [Array] deprecated, use entity_fields instead
    # @param metadata_fields [Hash] deprecated, use jsonb_fields instead
    # @param enum_fields [Hash{String => Hash}] configuration for enum/select fields
    # @param operations [Hash{String => String}] standard operation options (label => value)
    # @param enum_operations [Hash{String => String}] enum-specific operation options
    # rubocop:disable Metrics/ParameterLists
    def initialize(groups_form:, group_index:, condition:, condition_index:, condition_number:,
                   entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [], enum_fields: {},
                   operations: [], enum_operations: [])
      @groups_form = groups_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @condition_number = condition_number

      # Emit deprecation warnings for legacy parameter names
      deprecate_legacy_params(sample_fields, metadata_fields)

      # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
      @entity_fields = entity_fields.presence || sample_fields
      @jsonb_fields = jsonb_fields.presence || metadata_fields
      @enum_fields = enum_fields
      @operations = operations
      @enum_operations = enum_operations
    end
    # rubocop:enable Metrics/ParameterLists

    private

    # Emits deprecation warnings for legacy parameter names.
    def deprecate_legacy_params(sample_fields, metadata_fields)
      if sample_fields.present?
        Rails.logger.warn(
          '[DEPRECATION] AdvancedSearch::Condition: sample_fields is deprecated, use entity_fields instead'
        )
      end

      return if metadata_fields.blank?

      Rails.logger.warn(
        '[DEPRECATION] AdvancedSearch::Condition: metadata_fields is deprecated, use jsonb_fields instead'
      )
    end

    # Builds the I18n translation key for a condition attribute.
    #
    # @param attribute [Symbol] the attribute name (e.g., :field, :operator)
    # @return [String] the full translation key
    def translation_key(attribute)
      "activemodel.attributes.#{@condition.class.name.underscore}.#{attribute}"
    end

    # Returns the appropriate operations based on the current field type.
    #
    # Enum fields use a restricted set of operators (=, !=, in, not_in).
    # Standard fields use the full set of operators.
    #
    # @return [Hash{String => String}] operation options hash (label => value)
    def current_operations
      # Use enum operations if this condition's field is an enum
      @enum_fields.key?(@condition.field) ? @enum_operations : @operations
    end
  end
end
