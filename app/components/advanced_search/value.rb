# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search value
  class Value < Component
    def initialize(conditions_form:, group_index:, condition:, condition_index:, enum_fields: {})
      @conditions_form = conditions_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @enum_fields = enum_fields
    end

    def enum_field?
      @enum_fields.key?(@condition.field)
    end

    def enum_options
      return [] unless enum_field?

      @enum_fields[@condition.field]
    end
  end
end
