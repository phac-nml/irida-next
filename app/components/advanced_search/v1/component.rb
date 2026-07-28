# frozen_string_literal: true

module AdvancedSearch
  module V1
    # View component for advanced search component
    class Component < ::Component
      # @param sample_fields [Array] @deprecated Use fields: instead
      # @param metadata_fields [Array] @deprecated Use fields: instead
      # rubocop:disable Metrics/ParameterLists
      def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [], open: false, status: true)
        @form = form
        @search = search
        @fields = normalized_fields(fields:, sample_fields:, metadata_fields:)
        @operator_payload = operator_payload
        @operations = operation_options
        @open = open
        @status = status
        @search_group_class = @search.search_group_class
        @search_condition_class = @search.search_group_class.condition_class
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def normalized_fields(fields:, sample_fields:, metadata_fields:)
        return fields.symbolize_keys if fields.present?

        AdvancedSearch::Fields.for_samples(sample_fields:, metadata_fields:)
      end

      def enum_operation_options
        AdvancedSearch::OperatorRegistry.enum_options
      end

      def enum_operation_values
        AdvancedSearch::OperatorRegistry.enum_operator_values
      end

      def operation_options
        @operator_payload.slice('standard', 'metadata')
      end

      def operator_payload
        AdvancedSearch::OperatorRegistry.advanced_search_payload(
          metadata_operators_enabled: Flipper.enabled?(:advanced_search_metadata_operators)
        )
      end
    end
  end
end
