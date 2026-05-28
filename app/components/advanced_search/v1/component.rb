# frozen_string_literal: true

module AdvancedSearch
  module V1
    # View component for advanced search component
    class Component < ::Component
      # @param sample_fields [Array] @deprecated Use fields: instead
      # @param metadata_fields [Array] @deprecated Use fields: instead
      # rubocop:disable Metrics/ParameterLists
      def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [], open: false, status: true,
                     search_group_class: nil, search_condition_class: nil, toolbar_item: false)
        @form = form
        @search = search
        @fields = normalized_fields(fields:, sample_fields:, metadata_fields:)
        @operations = operation_options
        @open = open
        @status = status
        @toolbar_item = toolbar_item
        @search_group_class = search_group_class || @search.search_group_class
        @search_condition_class = search_condition_class || @search_group_class.condition_class
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def normalized_fields(fields:, sample_fields:, metadata_fields:)
        return fields.symbolize_keys if fields.present?

        AdvancedSearch::Fields.for_samples(sample_fields:, metadata_fields:)
      end

      def enum_operation_options
        operation_options.select { |_, value| enum_operation_values.include?(value) }
      end

      def enum_operation_values
        AdvancedSearch::ENUM_OPERATOR_VALUES
      end

      def operation_options
        {
          I18n.t('components.advanced_search_component.v1.operation.equals') => '=',
          I18n.t('components.advanced_search_component.v1.operation.not_equals') => '!=',
          I18n.t('components.advanced_search_component.v1.operation.less_than') => '<=',
          I18n.t('components.advanced_search_component.v1.operation.greater_than') => '>=',
          I18n.t('components.advanced_search_component.v1.operation.contains') => 'contains',
          I18n.t('components.advanced_search_component.v1.operation.does_not_contain') => 'not_contains',
          I18n.t('components.advanced_search_component.v1.operation.exists') => 'exists',
          I18n.t('components.advanced_search_component.v1.operation.not_exists') => 'not_exists',
          I18n.t('components.advanced_search_component.v1.operation.in') => 'in',
          I18n.t('components.advanced_search_component.v1.operation.not_in') => 'not_in'
        }
      end
    end
  end
end
