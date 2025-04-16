# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search condition
  class Condition < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(groups_form:, group_index:, condition:, condition_index:, sample_fields: [], metadata_fields: [],
                   operations: [])
      @groups_form = groups_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @sample_fields = sample_fields
      @metadata_fields = metadata_fields
      @operations = operations
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
