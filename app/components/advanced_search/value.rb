# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search value
  class Value < Component
    def initialize(conditions_form:, group_index:, condition:, condition_index:, fields: {})
      @conditions_form = conditions_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @fields = fields
    end

    private

    def enum_field?
      enum_field_config.present?
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
      labels = enum_field_config.fetch(:labels, {}) if enum_field_config
      translation_key = enum_field_config&.fetch(:translation_key, nil)

      return labels[value.to_s] if labels&.key?(value.to_s)
      return I18n.t("#{translation_key}.#{value}", default: value.to_s.humanize) if translation_key

      value.to_s.humanize
    end

    def selected_field
      @selected_field ||= @condition.field.to_s
    end

    def enum_fields
      @fields.fetch(:enum_fields, {})
    end

    def selected_enum_values
      Array(@condition.value).compact_blank.map(&:to_s)
    end

    def value_label
      @condition.class.human_attribute_name(:value)
    end
  end
end
