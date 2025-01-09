# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search group
  class Group < Component
    def initialize(form:, group:, group_index:, fields: [], operations: [])
      @form = form
      @group = group
      @group_index = group_index
      @fields = fields
      @operations = operations
    end
  end
end
