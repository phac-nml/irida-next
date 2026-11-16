# frozen_string_literal: true

module AdvancedSearch
  module V1
    # View component for advanced search component
    class Component < ::Component
      # @param sample_fields [Array] @deprecated Use fields: instead
      # @param metadata_fields [Array] @deprecated Use fields: instead
      # rubocop:disable-next Metrics/ParameterLists
      def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [], open: false, status: true)
        @form = form
        @search = search
        @fields = normalized_fields(fields:, sample_fields:, metadata_fields:)
        @operations = AdvancedSearch::OperatorCatalog.ui_options(
          metadata_operators_enabled: Flipper.enabled?(:advanced_search_metadata_operators)
        )
        @open = open
        @status = status
        @search_group_class = @search.search_group_class
        @search_condition_class = @search.search_group_class.condition_class
      end

      private

      def normalized_fields(fields:, sample_fields:, metadata_fields:)
        return fields.symbolize_keys if fields.present?

        AdvancedSearch::Fields.for_samples(sample_fields:, metadata_fields:)
      end

      def numeric_fields
        @fields.fetch(:numeric_fields, [])
      end

      def date_fields
        @fields.fetch(:date_fields, [])
      end
    end
  end
end
