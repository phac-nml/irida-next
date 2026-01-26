# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search group.
  #
  # A group contains multiple conditions that are combined with AND logic.
  # Multiple groups are combined with OR logic. Users can add/remove conditions
  # within a group and add/remove groups from the search.
  #
  # @example Rendering a group
  #   render AdvancedSearch::Group.new(
  #     form: form,
  #     group: search_group,
  #     group_index: 0,
  #     group_number: 1,
  #     show_remove_group_button: false,
  #     entity_fields: entity_field_options,
  #     enum_fields: enum_field_config,
  #     operations: standard_operations,
  #     enum_operations: enum_operations
  #   )
  class Group < Component
    # Initializes the group component.
    #
    # @param form [ActionView::Helpers::FormBuilder] the parent form builder
    # @param group [SearchGroup] the group model object containing conditions
    # @param group_index [Integer, String] the index of this group in the form
    # @param group_number [Integer] the display number for the group legend (1-based)
    # @param show_remove_group_button [Boolean] whether to show the remove group button
    # @param entity_fields [Array] select options for entity fields
    # @param jsonb_fields [Hash] grouped select options for JSONB/metadata fields
    # @param sample_fields [Array] deprecated, use entity_fields instead
    # @param metadata_fields [Hash] deprecated, use jsonb_fields instead
    # @param enum_fields [Hash{String => Hash}] configuration for enum/select fields
    # @param operations [Hash{String => String}] standard operation options (label => value)
    # @param enum_operations [Hash{String => String}] enum-specific operation options
    # rubocop:disable Metrics/ParameterLists
    def initialize(form:, group:, group_index:, group_number:, show_remove_group_button:,
                   entity_fields: [], jsonb_fields: [], sample_fields: [], metadata_fields: [], enum_fields: {},
                   operations: [], enum_operations: [])
      @form = form
      @group = group
      @group_index = group_index
      @group_number = group_number
      @show_remove_group_button = show_remove_group_button

      # Emit deprecation warnings for legacy parameter names
      deprecate_legacy_params(sample_fields, metadata_fields)

      # Support both new generic parameters and legacy sample-specific parameters for backward compatibility
      @entity_fields = entity_fields.presence || sample_fields
      @jsonb_fields = jsonb_fields.presence || metadata_fields
      @enum_fields = enum_fields
      @operations = operations
      @enum_operations = enum_operations
    end
    # rubocop:enable Metrics/ParameterLists

    private

    # Emits deprecation warnings for legacy parameter names.
    def deprecate_legacy_params(sample_fields, metadata_fields)
      if sample_fields.present?
        Rails.logger.warn(
          '[DEPRECATION] AdvancedSearch::Group: sample_fields is deprecated, use entity_fields instead'
        )
      end

      return if metadata_fields.blank?

      Rails.logger.warn(
        '[DEPRECATION] AdvancedSearch::Group: metadata_fields is deprecated, use jsonb_fields instead'
      )
    end
  end
end
