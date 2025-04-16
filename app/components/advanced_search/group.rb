# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search group
  class Group < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(form:, group:, group_index:, show_remove_group_button:, sample_fields: [], metadata_fields: [],
                   operations: [])
      @form = form
      @group = group
      @group_index = group_index
      @show_remove_group_button = show_remove_group_button
      @sample_fields = sample_fields
      @metadata_fields = metadata_fields
      @operations = operations
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
