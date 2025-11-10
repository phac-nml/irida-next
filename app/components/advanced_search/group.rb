# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search group
  class Group < Component
    # rubocop:disable Metrics/ParameterLists
    def initialize(form:, group:, group_index:, group_number:, show_remove_group_button:,
                   entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [], operations: [])
      @form = form
      @group = group
      @group_index = group_index
      @group_number = group_number
      @show_remove_group_button = show_remove_group_button

      # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
      @entity_fields = entity_fields.presence || sample_fields
      @jsonb_fields = jsonb_fields.presence || metadata_fields
      @operations = operations
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
