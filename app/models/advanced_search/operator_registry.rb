# frozen_string_literal: true

module AdvancedSearch
  # Central registry for all advanced-search operators and their behavior.
  class OperatorRegistry # rubocop:disable Metrics/ClassLength
    METADATA_GROUP_LABEL_KEYS = {
      existence: 'components.advanced_search_component.v1.operations.metadata.labels.existence',
      text: 'components.advanced_search_component.v1.operations.metadata.labels.text',
      numeric: 'components.advanced_search_component.v1.operations.metadata.labels.numeric',
      date: 'components.advanced_search_component.v1.operations.metadata.labels.date'
    }.freeze

    OPERATOR_DEFINITIONS = {
      '=' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.equals',
        standard: true,
        enum: true,
        handler: :apply_condition_equals,
        graphql_name: 'EQUALS'
      },
      '!=' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.not_equals',
        standard: true,
        enum: true,
        handler: :apply_condition_not_equals,
        graphql_name: 'NOT_EQUALS'
      },
      '<=' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.less_than',
        standard: true,
        handler: :apply_condition_standard_less_than_or_equal,
        graphql_name: 'LESS_THAN_EQUALS'
      },
      '>=' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.greater_than',
        standard: true,
        handler: :apply_condition_standard_greater_than_or_equal,
        graphql_name: 'GREATER_THAN_EQUALS'
      },
      'contains' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.contains',
        standard: true,
        handler: :apply_condition_contains,
        graphql_name: 'CONTAINS'
      },
      'not_contains' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.does_not_contain',
        standard: true,
        handler: :apply_condition_not_contains,
        graphql_name: 'NOT_CONTAINS'
      },
      'exists' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.exists',
        standard: true,
        metadata_group: :existence,
        no_value: true,
        handler: :apply_condition_exists,
        graphql_name: 'EXISTS'
      },
      'not_exists' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.not_exists',
        standard: true,
        metadata_group: :existence,
        no_value: true,
        handler: :apply_condition_not_exists,
        graphql_name: 'NOT_EXISTS'
      },
      'in' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.in',
        standard: true,
        enum: true,
        list_value: true,
        handler: :apply_condition_in,
        graphql_name: 'IN'
      },
      'not_in' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.not_in',
        standard: true,
        enum: true,
        list_value: true,
        handler: :apply_condition_not_in,
        graphql_name: 'NOT_IN'
      },
      'starts_with' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.starts_with',
        standard: true,
        handler: :apply_condition_starts_with
      },
      'ends_with' => {
        label_key: 'components.advanced_search_component.v1.operations.standard.ends_with',
        standard: true,
        handler: :apply_condition_ends_with
      },
      'text_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_equals',
        metadata_group: :text,
        handler: :apply_condition_equals
      },
      'text_not_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_not_equals',
        metadata_group: :text,
        handler: :apply_condition_not_equals
      },
      'text_contains' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_contains',
        metadata_group: :text,
        handler: :apply_condition_contains
      },
      'text_not_contains' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_not_contains',
        metadata_group: :text,
        handler: :apply_condition_not_contains
      },
      'text_in' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_in',
        metadata_group: :text,
        list_value: true,
        handler: :apply_condition_metadata_in
      },
      'text_not_in' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_not_in',
        metadata_group: :text,
        list_value: true,
        handler: :apply_condition_metadata_not_in
      },
      'text_starts_with' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_starts_with',
        metadata_group: :text,
        handler: :apply_condition_starts_with
      },
      'text_ends_with' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.text.text_ends_with',
        metadata_group: :text,
        handler: :apply_condition_ends_with
      },
      'numeric_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.numeric.numeric_equals',
        metadata_group: :numeric,
        handler: :apply_condition_metadata_numeric_equals
      },
      'numeric_not_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.numeric.numeric_not_equals',
        metadata_group: :numeric,
        handler: :apply_condition_metadata_numeric_not_equals
      },
      'numeric_less_than_equals' => {
        label_key:
          'components.advanced_search_component.v1.operations.metadata.operations.numeric.numeric_less_than_equals',
        metadata_group: :numeric,
        handler: :apply_condition_metadata_numeric_less_than_or_equal
      },
      'numeric_greater_than_equals' => {
        label_key:
          'components.advanced_search_component.v1.operations.metadata.operations.numeric.numeric_greater_than_equals',
        metadata_group: :numeric,
        handler: :apply_condition_metadata_numeric_greater_than_or_equal
      },
      'date_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.date.date_equals',
        metadata_group: :date,
        handler: :apply_condition_equals
      },
      'date_not_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.date.date_not_equals',
        metadata_group: :date,
        handler: :apply_condition_not_equals
      },
      'date_less_than_equals' => {
        label_key: 'components.advanced_search_component.v1.operations.metadata.operations.date.date_less_than_equals',
        metadata_group: :date,
        handler: :apply_condition_metadata_date_less_than_or_equal
      },
      'date_greater_than_equals' => {
        label_key:
          'components.advanced_search_component.v1.operations.metadata.operations.date.date_greater_than_equals',
        metadata_group: :date,
        handler: :apply_condition_metadata_date_greater_than_or_equal
      }
    }.freeze

    class << self
      def standard_options
        translated_options(standard_operator_values)
      end

      def metadata_grouped_options
        metadata_operator_values_by_group.each_with_object({}) do |(group_key, operators), grouped_options|
          grouped_options[I18n.t(METADATA_GROUP_LABEL_KEYS.fetch(group_key))] = translated_options(operators)
        end
      end

      def enum_options
        translated_options(enum_operator_values)
      end

      def enum_operator_values
        operator_values_for(:enum)
      end

      def filtering_handler_map
        OPERATOR_DEFINITIONS.transform_values { |definition| definition.fetch(:handler) }
      end

      def no_value_operator_values
        operator_values_for(:no_value)
      end

      def list_value_operator_values
        operator_values_for(:list_value)
      end

      def metadata_date_operator_values
        metadata_operator_values_by_group.fetch(:date)
      end

      def metadata_numeric_operator_values
        metadata_operator_values_by_group.fetch(:numeric)
      end

      def date_disallowed_operator_values
        %w[contains not_contains in not_in starts_with ends_with]
      end

      def combinable_operator_sets
        {
          gleqt: %w[>= <=],
          start_ends_with: %w[ends_with starts_with],
          metadata_date_gleqt: %w[date_greater_than_equals date_less_than_equals],
          metadata_numeric_gleqt: %w[numeric_greater_than_equals numeric_less_than_equals],
          text_starts_ends_with: %w[text_ends_with text_starts_with]
        }
      end

      def standard_operator_values
        OPERATOR_DEFINITIONS.filter_map do |operator, definition|
          operator if definition[:standard]
        end
      end

      def sample_graphql_operators
        standard_operator_values.filter_map do |operator|
          graphql_name = OPERATOR_DEFINITIONS.dig(operator, :graphql_name)
          [graphql_name, operator] if graphql_name.present?
        end
      end

      def advanced_search_payload(metadata_operators_enabled:)
        payload = {
          'standard' => standard_options,
          'enum' => enum_options
        }

        payload['metadata'] = metadata_grouped_options if metadata_operators_enabled
        payload
      end

      private

      def metadata_operator_values_by_group
        OPERATOR_DEFINITIONS.each_with_object({ existence: [], text: [], numeric: [],
                                                date: [] }) do |(operator, definition), grouped|
          metadata_group = definition[:metadata_group]
          grouped[metadata_group] << operator if metadata_group
        end
      end

      def translated_options(operators)
        operators.index_by do |operator|
          I18n.t(OPERATOR_DEFINITIONS.dig(operator, :label_key))
        end
      end

      def operator_values_for(attribute)
        OPERATOR_DEFINITIONS.filter_map do |operator, definition|
          operator if definition[attribute]
        end
      end
    end
  end
end
