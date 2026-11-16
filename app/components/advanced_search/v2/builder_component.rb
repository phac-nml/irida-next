# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Host-agnostic advanced search form builder.
    #
    # Renders the groups/conditions builder and the client-side <template> elements.
    # Has no knowledge of its host (dialog, drawer, page); a host adapter mounts it and
    # drives its lifecycle through the advanced-search--v2--builder Stimulus outlet.
    class BuilderComponent < ::Component
      def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [])
        @form = form
        @search = search
        @fields = normalized_fields(fields:, sample_fields:, metadata_fields:)
        @operations = AdvancedSearch::OperatorCatalog.ui_options(
          metadata_operators_enabled: Flipper.enabled?(:advanced_search_metadata_operators)
        )
        @search_group_class = @search.search_group_class
        @search_condition_class = @search.search_group_class.condition_class
      end

      private

      def initial_state
        @search.groups.map do |group|
          group.conditions.map do |condition|
            { field: condition.field, operator: condition.operator, values: Array(condition.value) }
          end
        end
      end

      def normalized_fields(fields:, sample_fields:, metadata_fields:)
        return fields.symbolize_keys if fields.present?

        AdvancedSearch::Fields.for_samples(sample_fields:, metadata_fields:)
      end
    end
  end
end
