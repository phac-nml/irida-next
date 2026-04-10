# frozen_string_literal: true

module AdvancedSearch
  module V1
    # Component for rendering an advanced search condition
    class ConditionComponent < ::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(groups_form:, group_index:, condition:, condition_index:, condition_number:, fields: {},
                     operations: [])
        @groups_form = groups_form
        @group_index = group_index
        @condition = condition
        @condition_index = condition_index
        @condition_number = condition_number
        @fields = fields
        @operations = operations
      end
      # rubocop:enable Metrics/ParameterLists

      def value_options
        return nil unless enum_field?

        enum_field_options
      end

      private

      def field_options
        @fields.fetch(:options, [])
      end

      def grouped_field_options
        @fields.fetch(:groups, {})
      end

      def field_label
        @condition.class.human_attribute_name(:field)
      end

      def operator_label
        @condition.class.human_attribute_name(:operator)
      end

      def operation_options
        enum_field? ? enum_operator_options : @operations
      end

      def enum_field?
        enum_fields.key?(selected_field)
      end

      def selected_field
        @condition.field.to_s
      end

      def enum_fields
        @fields.fetch(:enum_fields, {})
      end

      def enum_operator_options
        @operations.select { |_, value| enum_operator_values.include?(value) }
      end

      def enum_operator_values
        AdvancedSearch::ENUM_OPERATOR_VALUES
      end

      def enum_field_config
        return if selected_field.blank?

        enum_fields.fetch(selected_field, nil)
      end

      def enum_field_values
        @enum_field_values ||= Array(enum_field_config&.fetch(:values, nil))
      end

      def enum_field_options
        enum_field_values.map { |value| [enum_field_option_label(value), value] }
      end

      def enum_field_option_label(value)
        labels = {}
        labels = enum_field_config.fetch(:labels, {}) if enum_field_config
        translation_key = enum_field_config&.fetch(:translation_key, nil)

        return labels[value.to_s] if labels&.key?(value.to_s)
        return I18n.t("#{translation_key}.#{value}", default: value.to_s.humanize) if translation_key

        value.to_s.humanize
      end
    end
  end
end
