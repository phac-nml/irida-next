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

      # Builds the base HTML attributes for the checkbox input.
      #
      # Combines standard input attributes with ARIA attributes for accessibility.
      # Includes id, name, value, checked state, disabled state, and CSS classes.
      #
      # @return [Hash] hash of HTML attributes for the checkbox input
      # @api private
      def attributes
        base_attrs = {
          type: 'checkbox',
          id: input_id,
          name: input_name,
          value: @value,
          checked: @checked,
          disabled: @disabled,
          class: input_classes(@class)
        }

        # Build ARIA attributes
        aria_attrs = {}
        assign_if_present(aria_attrs, :label, @aria_label)
        assign_if_present(aria_attrs, :labelledby, @aria_labelledby)
        assign_if_present(aria_attrs, :live, @aria_live)
        assign_if_present(aria_attrs, :controls, @controls)

        # Add describedby for help text
        aria_attrs[:describedby] = help_text_id if @help_text.present?

        # Add existing described_by if present
        if @described_by.present?
          existing_describedby = aria_attrs[:describedby]
          aria_attrs[:describedby] = [existing_describedby, @described_by].compact.join(' ')
        end

        # Add controls describedby if controls are present
        if @controls.present?
          existing_describedby = aria_attrs[:describedby]
          aria_attrs[:describedby] = join_describedby(existing_describedby)
        end

        # Add ARIA attributes if any exist
        base_attrs[:aria] = aria_attrs unless aria_attrs.empty?

        # Add role if present
        base_attrs[:role] = @role if @role.present?

        # Add onchange if present
        base_attrs[:onchange] = @onchange if @onchange.present?

        # Add any additional HTML options
        base_attrs.merge(@html_options || {})
      end

      # Extracts and processes options from the constructor parameters.
      #
      # Separates standard options from HTML attributes and processes
      # accessibility, behavior, and styling options.
      #
      # @param options [Hash] the options hash from constructor
      # @return [void]
      # @api private
      def extract_options!(options)
        extract_basic_options(options)
        extract_accessibility_options(options)
        extract_behavior_options(options)
        @html_options = options # Store remaining options
      end

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

      # Merges form attributes with enhanced ARIA support.
      #
      # Overrides the base FormHelper method to add checkbox-specific
      # ARIA attributes and role information.
      #
      # @return [Hash] enhanced form attributes with ARIA support
      def form_attributes
        attributes = super
        attributes[:aria] = merged_aria(attributes[:aria])
        attributes[:role] = @role if @role.present?
        attributes
      end

      private

      # Extracts basic options from the constructor parameters.
      #
      # Processes fundamental checkbox options like input name, label,
      # checked state, disabled state, CSS classes, and text content.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      # @api private
      def extract_basic_options(options)
        @input_name = options.delete(:input_name)
        @label = options.delete(:label)
        @checked = options.delete(:checked) || false
        @disabled = options.delete(:disabled) || false
        @class = options.delete(:class)
        @help_text = options.delete(:help_text)
        @error_text = options.delete(:error_text)
      end

      # Extracts accessibility-related options from constructor parameters.
      #
      # Processes ARIA attributes, roles, and accessibility-specific
      # configuration options for screen readers and assistive technology.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      # @api private
      def extract_accessibility_options(options)
        @aria_label = options.delete(:aria_label)
        @described_by = options.delete(:described_by)
        @aria_labelledby = options.delete(:aria_labelledby)
        @controls = options.delete(:controls)
        @role = options.delete(:role)
        @aria_live = options.delete(:aria_live)
      end

      # Extracts behavior and interaction options from constructor parameters.
      #
      # Processes language settings, event handlers, and user feedback
      # messages for checkbox state changes.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      # @api private
      def extract_behavior_options(options)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @selected_message = options.delete(:selected_message)
        @deselected_message = options.delete(:deselected_message)
      end

      # Merges ARIA attributes with existing attributes.
      #
      # Combines provided ARIA attributes with component-specific ones,
      # handling describedby relationships and control associations.
      #
      # @param existing_aria [Hash, nil] existing ARIA attributes
      # @return [Hash] merged ARIA attributes
      # @api private
      def merged_aria(existing_aria)
        aria = existing_aria ? existing_aria.dup : {}
        assign_if_present(aria, :label, @aria_label)
        assign_if_present(aria, :labelledby, @aria_labelledby)
        assign_if_present(aria, :live, @aria_live)

        if @controls.present?
          aria[:controls] = @controls
          aria[:describedby] = join_describedby(aria[:describedby])
        end

        aria
      end

      # Determines if the component should re-render based on argument changes.
      #
      # Implements basic memoization to skip unnecessary re-renders when
      # the component arguments haven't changed since the last render.
      #
      # @return [Boolean] true if component should render, false to skip
      # @api private
      def should_render?
        @last_render_args != [@form, @attribute, @value, @options]
      end

      # Stores current render arguments for comparison in next render cycle.
      #
      # Called before rendering to capture the current state for
      # comparison in future render cycles to enable memoization.
      #
      # @return [void]
      # @api private
      def before_render
        @last_render_args = [@form, @attribute, @value, @options.dup]
      end
    end
  end
end
