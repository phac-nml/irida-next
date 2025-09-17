# frozen_string_literal: true

require_relative '../styles/form_styles'

module Pathogen
  module FormBuilders
    # FormBuilder for Pathogen
    #
    # This class extends the Rails FormBuilder to provide additional functionality
    # for building forms in Pathogen. It includes methods for adding test selectors,
    # custom classes, and other enhancements.
    #
    # @see https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html
    class PathogenFormBuilder < ActionView::Helpers::FormBuilder
      # Include the TestSelectorHelper module to handle test selectors
      # in a Rails-friendly way.
      include Pathogen::TestSelectorHelper
      include ActionView::Helpers::TagHelper
      include Pathogen::Styles::FormStyles

      def field_set_tag(&)
        # Format the fieldset tag so it looks kick ass
        @template.field_set_tag(class: 'grid grid-cols-1 gap-4', &)
      end

      # Renders a radio button with consistent styling and accessibility features
      #
      # @param attribute_name [Symbol] The attribute name for the radio button
      # @param value [String, Symbol, Boolean] The value for this radio button
      # @param options [Hash] Options for the radio button
      # @option options [String] :label Custom label text (defaults to humanized attribute name)
      # @option options [Boolean] :checked Whether the radio button should be checked
      # @option options [Boolean] :disabled Whether the radio button is disabled
      # @option options [Boolean] :required Whether the radio button is required
      # Pass ARIA attributes via `aria: { describedby:, controls: }`
      # @option options [String] :lang Language code for the label
      # @option options [String] :class Additional CSS classes
      # @option options [Boolean] :raw_input If true, only renders the input without wrapper or label
      # @return [String] HTML for the radio button
      def radio_button(attribute_name, value, options = {})
        options = add_test_selector(options)

        # Extract options for the component
        component_options = {
          form: self,
          attribute: attribute_name,
          value: value,
          label: options.delete(:label),
          checked: options.delete(:checked) { false },
          disabled: options.delete(:disabled) { false },
          required: options.delete(:required) { false },
          # described_by and controls must be provided via nested :aria
          lang: options.delete(:lang),
          class: options.delete(:class)
        }.merge(options)

        # Render the component
        @template.render(Pathogen::Form::RadioButton.new(**component_options))
      end

      # Renders a checkbox with consistent styling using standard Rails signature
      #
      # @param method [Symbol] The method name for the checkbox
      # @param options [Hash] Options for the checkbox
      # @param checked_value [String] Value when checked (default: "1")
      # @param unchecked_value [String] Value when unchecked (default: "0")
      # @return [String] HTML for the checkbox
      def check_box(method, options = {}, checked_value = '1', unchecked_value = '0')
        options = add_test_selector(options)
        options = apply_pathogen_styling(options)

        # Call the default Rails check_box implementation with our enhanced options
        super
      end
    end
  end
end
