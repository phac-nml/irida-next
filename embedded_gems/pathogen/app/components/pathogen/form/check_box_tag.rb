# frozen_string_literal: true

# Standalone checkbox component for Pathogen design system.
#
# This component renders only the checkbox input element with Pathogen styling
# for standalone field usage (check_box_tag). It follows the exact signature
# and behavior of Rails' check_box_tag helper.
#
# @example Basic usage
#   <%= check_box_tag("sample_quality", "approved") %>
#
# @example With custom values and state
#   <%= check_box_tag("newsletter", "yes", true, { class: "custom-class" }) %>
#
# @example Array field pattern
#   <%= check_box_tag("sample_ids[]", "123", false, { id: "sample-123" }) %>
#
# @since 3.1.0
module Pathogen
  module Form
    # Standalone checkbox component.
    #
    # Renders only the checkbox input element with Pathogen styling for standalone fields.
    # Uses field naming conventions (name="field_name" value="field_value").
    #
    # @since 3.1.0
    class CheckBoxTag < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include CheckboxStyling

      # Initialize checkbox component for standalone field usage
      #
      # @param name [String] the field name
      # @param value [String] the field value (default: "1")
      # @param checked [Boolean] whether the checkbox is checked (default: false)
      # @param options [Hash] HTML options for the checkbox
      def initialize(name, value = '1', checked = false, options = {}) # rubocop:disable Style/OptionalBooleanParameter
        super()

        @name = name.to_s
        @value = value.to_s
        @checked = checked

        # Extract Rails-specific options
        options ||= {}
        @include_hidden = options.delete(:include_hidden) { true }

        # Store remaining HTML options for the input
        @html_options = options
      end

      # Renders the checkbox component HTML - just the input with styling
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def call
        html = ''.html_safe
        html += render_hidden_field(@name, unchecked_value) if @include_hidden != false
        html += render_checkbox_input
        html
      end

      private

      # Renders the checkbox input element
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox input HTML
      def render_checkbox_input
        attrs = build_checkbox_attributes
        attrs[:name] = @name
        attrs[:value] = @value
        attrs[:id] = @html_options[:id] if @html_options[:id].present?

        tag.input(**attrs)
      end

      # Returns the unchecked value (always "0" for check_box_tag pattern)
      #
      # @return [String] the unchecked value
      def unchecked_value
        '0'
      end
    end
  end
end
