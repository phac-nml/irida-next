# frozen_string_literal: true

require_relative '../styles/form_styles'
require_relative '../test_selector_helper'

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
      def checkbox(method, options = {}, checked_value = '1', unchecked_value = '0')
        options = add_test_selector(options)
        options = apply_pathogen_styling(options)

        # Call the default Rails check_box implementation with our enhanced options
        super
      end
      alias check_box checkbox

      # Renders a label with consistent styling and required field indicators
      #
      # Overrides the default Rails form builder's label method to provide
      # automatic required field indicators when data-required="true" is present
      # in the options. The required indicator is added as an HTML abbr element
      # rather than relying on CSS pseudo-elements for better semantic meaning.
      #
      # @param method [Symbol] The method name for the label
      # @param content_or_options [String, Hash] Either content text or options hash
      # @param options [Hash] Options for the label (if content_or_options is String)
      # @return [String] HTML for the label with required indicator if needed
      #
      # @example Basic usage with data hash
      #   f.label :name, "Full Name", data: { required: "true" }
      #
      # @example Basic usage with string attribute
      #   f.label :email, "Email", "data-required" => "true"
      #
      # @example With block content
      #   f.label :email, data: { required: "true" } do
      #     "Email Address"
      #   end
      def label(method, content_or_options = nil, options = nil, &)
        options, content_or_options = normalize_label_params(content_or_options, options)
        options = add_test_selector(options)

        is_required = required_field?(options)

        # Remove the data-required attribute after determining the required state
        remove_required_attributes(options) if is_required

        return super unless is_required

        enhanced_content = build_enhanced_label_content(method, content_or_options, &)
        super(method, enhanced_content, options)
      end

      private

      def normalize_label_params(content_or_options, options)
        if content_or_options.is_a?(Hash)
          [content_or_options, nil]
        else
          [options || {}, content_or_options]
        end
      end

      def required_field?(options)
        # Pull the potential required flag from typical locations and
        # treat only "true" or "1" (or their non-string equivalents) as required.
        val = options.dig(:data, :required) || options.dig(:data, 'required') || options['data-required']
        %w[true 1].include?(val.to_s)
      end

      def remove_required_attributes(options)
        # Remove data-required attributes from various possible locations
        options[:data]&.delete(:required)
        options[:data]&.delete('required')
        options.delete('data-required')
      end

      def build_enhanced_label_content(method, content_or_options, &)
        base_content = determine_base_content(method, content_or_options, &)
        append_required_indicator(base_content)
      end

      def determine_base_content(method, content_or_options, &)
        return @template.capture(&) if block_given?
        return content_or_options.to_s if content_or_options

        # Use Rails' built-in label translation lookup
        if @object&.class&.respond_to?(:human_attribute_name)
          @object.class.human_attribute_name(method)
        else
          method.to_s.humanize
        end
      end

      def append_required_indicator(content)
        safe_content = ERB::Util.html_escape(content.to_s.strip)
        required_abbr = @template.tag.abbr(
          I18n.t('pathogen.label.required_indicator'),
          class: 'req',
          title: I18n.t('pathogen.label.title')
        )
        @template.safe_join([safe_content, ' ', required_abbr])
      end
    end
  end
end
