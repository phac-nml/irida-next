# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search value
  class Value < Component
    def initialize(conditions_form:, group_index:, condition:, condition_index:)
      @conditions_form = conditions_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
    end
  end
end
