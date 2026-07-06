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
        operation_options['standard'].select { |_, value| enum_operation_values.include?(value) }
      end

      def enum_operation_values
        AdvancedSearch::ENUM_OPERATOR_VALUES
      end

      def operation_options # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        standard_operations = { 'standard' => {
          I18n.t('components.advanced_search_component.v1.operations.standard.equals') => '=',
          I18n.t('components.advanced_search_component.v1.operations.standard.not_equals') => '!=',
          I18n.t('components.advanced_search_component.v1.operations.standard.less_than') => '<=',
          I18n.t('components.advanced_search_component.v1.operations.standard.greater_than') => '>=',
          I18n.t('components.advanced_search_component.v1.operations.standard.contains') => 'contains',
          I18n.t('components.advanced_search_component.v1.operations.standard.does_not_contain') => 'not_contains',
          I18n.t('components.advanced_search_component.v1.operations.standard.exists') => 'exists',
          I18n.t('components.advanced_search_component.v1.operations.standard.not_exists') => 'not_exists',
          I18n.t('components.advanced_search_component.v1.operations.standard.in') => 'in',
          I18n.t('components.advanced_search_component.v1.operations.standard.not_in') => 'not_in'
        } }

        return standard_operations unless Flipper.enabled?(:advanced_search_metadata_operators)

        metadata_operations =
          { 'metadata' => {
            I18n.t('components.advanced_search_component.v1.operations.metadata.labels.existence') =>
           {
             I18n.t('components.advanced_search_component.v1.operations.standard.exists') => 'exists',
             I18n.t('components.advanced_search_component.v1.operations.standard.not_exists') => 'not_exists'
           },
            I18n.t('components.advanced_search_component.v1.operations.metadata.labels.text') => {
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_equals') => 'text_equals', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_not_equals') => 'text_not_equals', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_contains') => 'text_contains', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_not_contains') => 'text_not_contains', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_in') => 'text_in', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.text.text_not_in') => 'text_not_in' # rubocop:disable Layout/LineLength
            },
            I18n.t("#{localization_key}.metadata.labels.numeric") => {
              I18n.t("#{localization_key}.metadata.operations.numeric.numeric_equals") => 'numeric_equals',
              I18n.t("#{localization_key}.metadata.operations.numeric.numeric_not_equals") => 'numeric_not_equals',
              I18n.t("#{localization_key}.metadata.operations.numeric.numeric_less_than_equals") =>
              'numeric_less_than_equals',
              I18n.t("#{localization_key}.metadata.operations.numeric.numeric_greater_than_equals") =>
              'numeric_greater_than_equals'
            },
            I18n.t('components.advanced_search_component.v1.operations.metadata.labels.date') => {
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.date.date_equals') => 'date_equals', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.date.date_not_equals') => 'date_not_equals', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.date.date_less_than_equals') => 'date_less_than_equals', # rubocop:disable Layout/LineLength
              I18n.t('components.advanced_search_component.v1.operations.metadata.operations.date.date_greater_than_equals') => 'date_greater_than_equals' # rubocop:disable Layout/LineLength
            }
          } }

        standard_operations.merge(metadata_operations)
      end
    end
  end
end
