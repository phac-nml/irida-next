# frozen_string_literal: true

module AdvancedSearch
  # Component for rendering an advanced search value input.
  #
  # Renders the appropriate input type based on the condition's field and operator:
  # - Select dropdown for enum fields with single-value operators (=, !=)
  # - Multi-select for enum fields with list operators (in, not_in)
  # - List filter component for non-enum list operators
  # - Text input for all other cases
  #
  # @example Rendering a value input
  #   render AdvancedSearch::Value.new(
  #     conditions_form: conditions_form,
  #     group_index: 0,
  #     condition: condition,
  #     condition_index: 0,
  #     enum_fields: { 'state' => { values: %w[running completed], labels: nil } }
  #   )
  class Value < Component
    # Initializes the value component.
    #
    # @param conditions_form [ActionView::Helpers::FormBuilder] the nested form builder for conditions
    # @param group_index [Integer, String] the index of the parent group
    # @param condition [SearchCondition] the condition model object
    # @param condition_index [Integer, String] the index of this condition within the group
    # @param enum_fields [Hash{String => Hash}] configuration for enum/select fields
    def initialize(conditions_form:, group_index:, condition:, condition_index:, enum_fields: {})
      @conditions_form = conditions_form
      @group_index = group_index
      @condition = condition
      @condition_index = condition_index
      @enum_fields = enum_fields
    end

    private

    # Builds the I18n translation key for a condition attribute.
    #
    # @param attribute [Symbol] the attribute name (e.g., :value)
    # @return [String] the full translation key
    def translation_key(attribute)
      "activemodel.attributes.#{@condition.class.name.underscore}.#{attribute}"
    end

    # Checks if the current condition's field is an enum field.
    #
    # @return [Boolean] true if the field has enum configuration
    def enum_field?
      @enum_fields.key?(@condition.field)
    end

    # Builds select options for enum fields.
    #
    # Uses labels hash if provided, otherwise falls back to I18n translation.
    #
    # @return [Array<Array(String, String)>] array of [label, value] pairs for select options
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

    # Checks if the current operator expects a list of values.
    #
    # @return [Boolean] true if operator is 'in' or 'not_in'
    def list_operator?
      %w[in not_in].include?(@condition.operator)
    end

    # Determines if a single-value enum select should be rendered.
    #
    # @return [Boolean] true if field is enum and operator is not a list operator
    def render_enum_select?
      enum_field? && !list_operator?
    end

    # Determines if a multi-select enum input should be rendered.
    #
    # @return [Boolean] true if field is enum and operator is a list operator
    def render_enum_multiselect?
      enum_field? && list_operator?
    end
  end
end
