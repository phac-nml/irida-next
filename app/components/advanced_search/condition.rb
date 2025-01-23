# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition
  class Condition < Component
    def initialize(groups_form:, group_index:, condition:, condition_index:, fields: [], operations: []) # rubocop:disable Metrics/ParameterLists
      @groups_form = groups_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @fields = fields
      @operations = operations
    end
  end
end
