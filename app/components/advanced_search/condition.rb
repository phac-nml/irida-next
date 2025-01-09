# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition
  class Condition < Component
    def initialize(groups_form:, condition:, fields: [], operations: [])
      @groups_form = groups_form
      @condition = condition
      @fields = fields
      @operations = operations
    end
  end
end
