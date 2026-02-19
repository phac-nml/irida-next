# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search group
  class Group < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(form:, group:, group_index:, group_number:, show_remove_group_button:, fields: {}, operations: [])
      @form = form
      @group = group
      @group_index = group_index
      @group_number = group_number
      @show_remove_group_button = show_remove_group_button
      @fields = fields
      @operations = operations
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
