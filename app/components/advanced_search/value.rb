# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search value
  class Value < Component
    def initialize(conditions_form:, group_index:, condition:, condition_index:, enum_fields: {})
      @conditions_form = conditions_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @enum_fields = enum_fields
    end

    private

    def translation_key(attribute)
      "activemodel.attributes.#{@condition.class.name.underscore}.#{attribute}"
    end

    def enum_field?
      @enum_fields.key?(@condition.field)
    end

    def enum_options
      return [] unless enum_field?

      enum_config = @enum_fields[@condition.field]
      values = enum_config[:values]
      labels = enum_config[:labels]

      values.map do |value|
        # Use labels if provided (for pre-translated values like workflow names),
        # otherwise fall back to translation key
        label = if labels&.key?(value)
                  labels[value]
                else
                  translation_key = enum_config[:translation_key]
                  I18n.t("#{translation_key}.#{value}")
                end
        [label, value]
      end
    end

    def list_operator?
      %w[in not_in].include?(@condition.operator)
    end

    def render_enum_select?
      enum_field? && !list_operator?
    end

    def render_enum_multiselect?
      enum_field? && list_operator?
    end
  end
end
