# frozen_string_literal: true

# 🟢 Pathogen::Form::Checkbox 🟢
#
# 🎯 Purpose:
#   This file defines a custom, accessible, and beautifully styled checkbox component for Rails forms.
#   - Designed for maximum accessibility (ARIA, labels, help text)
#   - Uses Tailwind CSS for modern, responsive styling
#   - Easy to use and extend in your Rails app
#
# 🚀 Usage Example:
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :terms,               # 🏷️  The model attribute (used for name/id if no form)
#     value: "1",                     # 💾 The value for this checkbox
#     label: "I agree to the terms",  # 🏷️  The label shown to users
#     help_text: "You must agree to continue." # 💡 Optional help text
#   ) %>
#   # Or with a form builder:
#   <%= render Pathogen::Form::Checkbox.new(
#     form: form,                      # 📝 Your form builder
#     attribute: :newsletter,
#     value: "1",
#     label: "Subscribe to newsletter"
#   ) %>
#   # Or with aria_label for screen reader only:
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :select_all,
#     value: "1",
#     aria_label: "Select all items on this page",
#     help_text: "Check to select all items, uncheck to deselect all"
#   ) %>
#
# 🧩 Options:
#   - :form         📝   (FormBuilder) — Optional. If not provided, input_name is used.
#   - :input_name   🏷️   (String)     — Optional. Used for input name/id if no form.
#   - :label        🏷️   (String)     — The label text shown next to the checkbox (required if no aria_label)
#   - :aria_label   🗣️   (String)     — Screen reader only label (required if no label)
#   - :checked      ✅   (Boolean)     — Whether this checkbox is selected
#   - :disabled     🚫   (Boolean)     — Whether this checkbox is disabled
#   - :described_by 🗣️   (String)     — ID of element describing this input
#   - :controls     🎛️   (String)     — ID of element controlled by this input
#   - :lang         🌐   (String)     — Language code
#   - :class        🎨   (String)     — Extra CSS classes
#   - :onchange     🔄   (String)     — JS for onchange event
#   - :help_text    💡   (String)     — Help text below the label (ARIA described)
#   - :error_text   🚨   (String)     — Error text to display when invalid
#
# ♿ Accessibility:
#   - Associates label and input for screen readers
#   - Uses aria-describedby for help text and error messages
#   - Keyboard and screen reader friendly
#   - Visible focus and checked states
#   - WCAG 2.1 AA compliant
#   - Requires either visible label or aria-label for accessibility
#
# 🛠️  How it works:
#   - Renders a checkbox input and label side-by-side
#   - Optionally renders help text and error messages below the label
#   - All ARIA and accessibility attributes are set automatically
#   - Styles are applied using Tailwind CSS utility classes
#
# 📚 See also:
#   - Pathogen::Form::CheckboxStyles for style helpers
#   - Pathogen::Form::FormHelpers for common form functionality
#
# ✨ Enjoy accessible, beautiful forms!

module Pathogen
  module Form
    # 🟢 Pathogen::Form::Checkbox 🟢
    #
    # This component renders a single checkbox with a label and optional help text.
    # It is designed for accessibility and modern UI using Tailwind CSS.
    # WCAG 2.1 AA compliant with proper label association.
    #
    # See the top of this file for full usage and options! 🎉
    class Checkbox < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
      include CheckboxStyles
      include FormHelper
      include CheckboxAccessibility

      # @param form [ActionView::Helpers::FormBuilder, nil] the form builder (optional)
      # @param attribute [Symbol] the attribute for the checkbox
      # @param value [String] the value for the checkbox
      # @param options [Hash] additional options:
      #   - :input_name [String] input name/id if no form is provided
      #   - :label [String] the label text (required if no aria_label)
      #   - :aria_label [String] screen reader only label (required if no label)
      #   - :checked [Boolean] whether the checkbox is checked
      #   - :disabled [Boolean] whether the checkbox is disabled
      #   - :described_by [String] id of element describing this input
      #   - :controls [String] id of element controlled by this input
      #   - :lang [String] language code
      #   - :class [String] additional CSS classes
      #   - :onchange [String] JS for onchange event
      #   - :help_text [String] help text rendered below the label
      #   - :role [String] ARIA role (e.g., 'checkbox', 'button')
      #   - :aria_live [String] ARIA live region for announcements
      def initialize(attribute:, value:, form: nil, **options)
        super()
        @form = form
        @attribute = attribute
        @value = value
        extract_options!(options)
        validate_accessibility_requirements!
      end

      def call
        if @label.blank?
          # No visible label - render with aria-label and help_text in sr-only
          render_aria_only_checkbox
        else
          # Has visible label - render standard layout
          render_labeled_checkbox
        end
      end

      # Satisfy FormHelpers contract for input_classes
      def input_classes(user_class)
        checkbox_classes(user_class)
      end

      # Override form_attributes to add enhanced ARIA support
      def form_attributes
        base_attributes = super
        enhanced_aria = base_attributes[:aria] || {}

        # Add custom ARIA attributes if provided
        enhanced_aria[:label] = @aria_label if @aria_label.present?
        enhanced_aria[:live] = @aria_live if @aria_live.present?
        # NOTE: role is NOT an ARIA attribute. It must be a top-level attribute.
        # enhanced_aria[:role] = @role if @role.present?  # ❌ remove this

        # For select-all checkboxes, add better controls and describedby
        if @controls.present?
          enhanced_aria[:controls] = @controls
          enhanced_aria[:describedby] = [enhanced_aria[:describedby], "#{input_id}_description"].compact.join(' ')
        end

        # Merge ARIA back
        base_attributes = base_attributes.merge(aria: enhanced_aria)

        # Promote role to top-level attribute so it renders as role="…"
        base_attributes[:role] = @role if @role.present?

        base_attributes
      end

      private

      # Validates that accessibility requirements are met
      def validate_accessibility_requirements!
        return unless @label.blank? && @aria_label.blank?

        raise ArgumentError, "Checkbox requires either 'label' or 'aria_label' for accessibility compliance"
      end

      # Renders checkbox with only aria-label (no visible label)
      def render_aria_only_checkbox
        tag.div(class: 'flex flex-col') do
          checkbox_html +
            tag.div(class: 'mt-1') do
              help_text_sr_only_html + enhanced_description_html
            end
        end
      end

      # Renders checkbox with visible label
      def render_labeled_checkbox
        tag.div(class: 'flex flex-col') do
          tag.div(class: 'flex items-center gap-3') do
            checkbox_html + label_html
          end +
            tag.div(class: 'mt-1 ml-8') do
              help_html + enhanced_description_html
            end
        end
      end

      # Renders the checkbox input element
      def checkbox_html
        check_box_tag(
          input_name,
          @value,
          @checked,
          form_attributes.merge(id: input_id).merge(@html_options)
        )
      end

      # Renders the label for the checkbox
      def label_html
        return if @label.blank?

        tag.label(@label, for: input_id, class: label_classes)
      end

      # Renders the help text below the label, if present
      def help_html
        if @help_text.present?
          tag.span(@help_text, id: help_text_id, class: help_text_classes)
        else
          ''.html_safe
        end
      end

      # Renders help text in screen reader only mode when no visible label
      def help_text_sr_only_html
        if @help_text.present?
          tag.span(@help_text, id: help_text_id, class: 'sr-only', 'aria-live': 'polite')
        else
          ''.html_safe
        end
      end

      # enhanced_description_html is provided by CheckboxAccessibility

      # Skip re-renders if the input hasn't changed
      # @api private
      def should_render?
        @last_render_args != [@form, @attribute, @value, @options]
      end

      # Store the current render arguments for comparison in the next render
      # @api private
      def before_render
        @last_render_args = [@form, @attribute, @value, @options.dup]
      end
    end
  end
end
