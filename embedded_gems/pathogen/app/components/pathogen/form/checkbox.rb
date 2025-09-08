# frozen_string_literal: true

# Accessible checkbox component for Rails forms with WCAG AAA compliance.
#
# This ViewComponent renders a fully accessible checkbox input with proper
# label association, ARIA attributes, and TailwindCSS styling. It supports
# both standalone usage and integration with Rails form builders.
#
# @example Basic usage with visible label
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :terms,
#     value: "1",
#     label: "I agree to the terms",
#     help_text: "You must agree to continue."
#   ) %>
#
# @example With Rails form builder
#   <%= form_with model: @user do |form| %>
#     <%= render Pathogen::Form::Checkbox.new(
#       form: form,
#       attribute: :newsletter,
#       value: "1",
#       label: "Subscribe to newsletter"
#     ) %>
#   <% end %>
#
# @example Screen reader only label (aria-label)
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :select_all,
#     value: "1",
#     aria_label: "Select all items on this page",
#     help_text: "Check to select all items, uncheck to deselect all"
#   ) %>
#
# @example Using aria-labelledby for external labeling
#   <h3 id="bulk-actions-heading">Bulk Actions</h3>
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :select_all,
#     value: "1",
#     aria_labelledby: "bulk-actions-heading",
#     help_text: "Select all items for bulk operations"
#   ) %>
#
# @note This component requires either a `label`, `aria_label`, or `aria_labelledby` parameter
#   for accessibility compliance.
#
# @see Pathogen::Form::CheckboxStyles for styling utilities
# @see Pathogen::Form::CheckboxAccessibility for accessibility helpers
# @see Pathogen::Form::FormHelper for common form functionality

module Pathogen
  module Form
    # Internal helper methods for the Checkbox component.
    #
    # These methods are extracted to a separate module to keep the main
    # Checkbox class focused and maintain single responsibility principle.
    # They handle internal operations like attribute assignment, ID generation,
    # and HTML rendering that don't need to be part of the public API.
    #
    # @api private
    # @since 1.0.0
    module CheckboxInternalHelpers
      # Assigns a value to a hash if the value is present (not blank).
      #
      # @param hash [Hash] the hash to modify
      # @param key [Symbol, String] the key to set
      # @param value [Object] the value to assign if present
      # @return [Hash] the modified hash
      # @api private
      def assign_if_present(hash, key, value)
        return hash if value.blank?

        hash[key] = value
        hash
      end

      # Joins the current aria-describedby value with the description ID.
      #
      # @param current [String, nil] existing aria-describedby value
      # @return [String] space-separated list of IDs
      # @api private
      def join_describedby(current)
        [current, "#{input_id}_description"].compact.join(' ')
      end

      # Generates the HTML ID for the checkbox input.
      #
      # Uses form object name and attribute when form is present,
      # otherwise falls back to input_name or attribute.
      # Includes the value to ensure unique IDs for multiple checkboxes.
      #
      # @return [String] the HTML ID for the input
      # @api private
      def input_id
        @input_id ||= if @form
                        "#{@form.object_name}_#{@attribute}_#{@value}"
                      else
                        base_name = @input_name || @attribute.to_s
                        "#{base_name}_#{@value}"
                      end
      end

      # Generates the HTML name attribute for the checkbox input.
      #
      # Uses Rails form naming convention when form is present,
      # otherwise uses the attribute name directly.
      #
      # @return [String] the HTML name attribute for the input
      # @api private
      def input_name
        @input_name ||= if @form
                          "#{@form.object_name}[#{@attribute}]"
                        else
                          @attribute.to_s
                        end
      end

      # Generates the ID for the help text element.
      #
      # @return [String] the HTML ID for the help text span
      # @api private
      def help_text_id
        "#{input_id}_help"
      end

      # Renders the checkbox input HTML element.
      #
      # Uses Rails check_box_tag helper with proper attributes and options.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox input HTML
      # @api private
      def checkbox_html
        check_box_tag(
          input_name,
          @value,
          @checked,
          attributes.merge(@html_options)
        )
      end

      # Renders the label HTML element if label text is present.
      #
      # @return [ActiveSupport::SafeBuffer, nil] the label HTML or nil
      # @api private
      def label_html
        return if @label.blank?

        tag.label(@label, for: input_id, class: label_classes)
      end

      # Renders the help text HTML element if help text is present.
      #
      # @return [ActiveSupport::SafeBuffer] the help text HTML or empty safe string
      # @api private
      def help_html
        if @help_text.present?
          tag.span(@help_text, id: help_text_id, class: help_text_classes)
        else
          ''.html_safe
        end
      end
    end

    # Accessible checkbox component for Rails forms.
    #
    # This ViewComponent renders a single checkbox input with proper label association,
    # help text, error handling, and WCAG AAA compliance. It supports both standalone
    # usage and integration with Rails form builders.
    #
    # @example Basic checkbox with visible label
    #   <%= render Pathogen::Form::Checkbox.new(
    #     attribute: :terms,
    #     value: "1",
    #     label: "I agree to the terms and conditions"
    #   ) %>
    #
    # @example With form builder and help text
    #   <%= form_with model: @user do |form| %>
    #     <%= render Pathogen::Form::Checkbox.new(
    #       form: form,
    #       attribute: :newsletter,
    #       value: "1",
    #       label: "Subscribe to newsletter",
    #       help_text: "We'll send you updates about new features"
    #     ) %>
    #   <% end %>
    #
    # @example Screen reader accessible (no visible label)
    #   <%= render Pathogen::Form::Checkbox.new(
    #     attribute: :select_all,
    #     value: "1",
    #     aria_label: "Select all items in the table",
    #     help_text: "Toggle to select or deselect all items"
    #   ) %>
    #
    # @example Using aria-labelledby to reference external label
    #   <h3 id="notification-settings">Notification Settings</h3>
    #   <%= render Pathogen::Form::Checkbox.new(
    #     attribute: :email_notifications,
    #     value: "1",
    #     aria_labelledby: "notification-settings",
    #     help_text: "Receive email notifications for important updates"
    #   ) %>
    #
    # @note Requires either `label`, `aria_label`, or `aria_labelledby` for accessibility compliance.
    #
    # @see CheckboxStyles for styling methods
    # @see CheckboxAccessibility for accessibility helpers
    # @see FormHelper for form integration utilities
    #
    # @since 1.0.0
    # @version 2.0.0
    class Checkbox < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::TranslationHelper
      include CheckboxStyles
      include FormHelper
      include CheckboxAccessibility
      include CheckboxInternalHelpers
      include CheckboxAttributes
      include CheckboxOptionExtractor
      include CheckboxRenderer

      # Initializes a new Checkbox component.
      #
      # @param attribute [Symbol] the model attribute name for the checkbox
      # @param value [String] the value to submit when checkbox is checked
      # @param form [ActionView::Helpers::FormBuilder, nil] optional form builder
      # @param input_name [String, nil] custom input name (used when no form provided)
      # @param label [String, nil] visible label text (required if no aria_label)
      # @param aria_label [String, nil] screen reader label (required if no label)
      # @param checked [Boolean] whether the checkbox is initially checked (default: false)
      # @param disabled [Boolean] whether the checkbox is disabled (default: false)
      # @param described_by [String, nil] ID of element describing this input
      # @param aria_labelledby [String, nil] ID of element that labels this input
      # @param controls [String, nil] ID of element controlled by this input
      # @param lang [String, nil] language code for the input
      # @param class [String, nil] additional CSS classes
      # @param onchange [String, nil] JavaScript for onchange event
      # @param help_text [String, nil] help text displayed below the label
      # @param error_text [String, nil] error text to display when invalid
      # @param role [String, nil] ARIA role (e.g., 'checkbox', 'button')
      # @param aria_live [String, nil] ARIA live region for announcements
      # @param selected_message [String, nil] message announced when selected
      # @param deselected_message [String, nil] message announced when deselected
      #
      # @raise [ArgumentError] if none of label, aria_label, or aria_labelledby is provided
      #
      # @example Basic usage
      #   Pathogen::Form::Checkbox.new(
      #     attribute: :terms,
      #     value: "1",
      #     label: "I agree to the terms"
      #   )
      #
      # @example With form builder
      #   Pathogen::Form::Checkbox.new(
      #     form: form_builder,
      #     attribute: :newsletter,
      #     value: "1",
      #     label: "Subscribe to newsletter",
      #     help_text: "We'll send monthly updates"
      #   )
      def initialize(attribute:, value:, form: nil, **options)
        super()
        @form = form
        @attribute = attribute
        @value = value
        extract_options!(options)
        validate_accessibility_requirements!
      end

      # Renders the checkbox component HTML.
      #
      # Determines the rendering strategy based on whether a visible label
      # is provided. Uses different templates for labeled vs aria-labeled checkboxes.
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def call
        if @label.blank?
          render_aria_only_checkbox
        else
          render_labeled_checkbox
        end
      end

      # Provides CSS classes for the checkbox input element.
      #
      # Satisfies the FormHelper contract for input_classes method.
      # Delegates to the CheckboxStyles module for consistent styling.
      #
      # @param user_class [String, nil] additional CSS classes from user
      # @return [String] complete CSS class string for the input
      def input_classes(user_class)
        checkbox_classes(user_class)
      end
    end
  end
end
