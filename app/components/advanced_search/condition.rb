# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition
  class Condition < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(groups_form:, group_index:, condition:, condition_index:, condition_number:, fields: {},
                   operations: [])
      @groups_form = groups_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @condition_number = condition_number
      @fields = fields
      @operations = operations
    end
    # rubocop:enable Metrics/ParameterLists

    private

    def field_options
      @fields.fetch(:options, [])
    end

    def grouped_field_options
      @fields.fetch(:groups, {})
    end

    def field_label
      @condition.class.human_attribute_name(:field)
    end

    def operator_label
      @condition.class.human_attribute_name(:operator)
    end

    def operation_options
      enum_field? ? enum_operator_options : @operations
    end

    def enum_field?
      enum_fields.key?(selected_field)
    end

    def selected_field
      @condition.field.to_s
    end

    def enum_fields
      @fields.fetch(:enum_fields, {})
    end

    def enum_operator_options
      @operations.select { |_label, value| enum_operator_values.include?(value) }
    end

    def enum_operator_values
      %w[= != in not_in]
    end
  end
end
