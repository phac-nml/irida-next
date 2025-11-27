# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition
  class Condition < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(groups_form:, group_index:, condition:, condition_index:, condition_number:,
                   entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [], enum_fields: {},
                   operations: [], enum_operations: [])
      @groups_form = groups_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @condition_number = condition_number

      # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
      @entity_fields = entity_fields.presence || sample_fields
      @jsonb_fields = jsonb_fields.presence || metadata_fields
      @enum_fields = enum_fields
      @operations = operations
      @enum_operations = enum_operations
    end
    # rubocop:enable Metrics/ParameterLists

    private

    def translation_key(attribute)
      "activemodel.attributes.#{@condition.class.name.underscore}.#{attribute}"
    end

    def current_operations
      # Use enum operations if this condition's field is an enum
      @enum_fields.key?(@condition.field) ? @enum_operations : @operations
    end
  end
end
