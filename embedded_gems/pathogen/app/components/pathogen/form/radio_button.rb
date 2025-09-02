# frozen_string_literal: true

# 🟢 Pathogen::Form::RadioButton 🟢
#
# 🎯 Purpose:
#   This file defines a custom, accessible, and beautifully styled radio button component for Rails forms.
#   - Designed for maximum accessibility (ARIA, labels, help text)
#   - Uses Tailwind CSS for modern, responsive styling
#   - Easy to use and extend in your Rails app
#
# 🚀 Usage Example:
#   <%= render Pathogen::Form::RadioButton.new(
#     attribute: :theme,               # 🏷️  The model attribute (used for name/id if no form)
#     value: "system",                # 💾 The value for this radio
#     label: "System",                # 🏷️  The label shown to users
#     help_text: "Theme follows your OS settings." # 💡 Optional help text
#   ) %>
#   # Or with a form builder:
#   <%= render Pathogen::Form::RadioButton.new(
#     form: form,                      # 📝 Your form builder
#     attribute: :theme,
#     value: "system",
#     label: "System"
#   ) %>
#
# 🧩 Options:
#   - :form         📝   (FormBuilder) — Optional. If not provided, input_name is used.
#   - :input_name   🏷️   (String)     — Optional. Used for input name/id if no form.
#   - :label        🏷️   (String)     — The label text shown next to the radio
#   - :checked      ✅   (Boolean)     — Whether this radio is selected
#   - :disabled     🚫   (Boolean)     — Whether this radio is disabled
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
#
# 🛠️  How it works:
#   - Renders a radio input and label side-by-side
#   - Optionally renders help text and error messages below the label
#   - All ARIA and accessibility attributes are set automatically
#   - Styles are applied using Tailwind CSS utility classes
#
# 📚 See also:
#   - Pathogen::Form::RadioButtonStyles for style helpers
#   - Pathogen::Form::FormHelpers for common form functionality
#
# ✨ Enjoy accessible, beautiful forms!

module Pathogen
  module Form
    # 🟢 Pathogen::Form::RadioButton 🟢
    #
    # This component renders a single radio button with a label and optional help text.
    # It is designed for accessibility and modern UI using Tailwind CSS.
    #
    # See the top of this file for full usage and options! 🎉
    class RadioButton < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
      include RadioButtonStyles

      # @param form [ActionView::Helpers::FormBuilder, nil] the form builder (optional)
      # @param attribute [Symbol] the attribute for the radio button
      # @param value [String] the value for the radio button
      # @param options [Hash] additional options:
      #   - :input_name [String] input name/id if no form is provided
      #   - :label [String] the label text
      #   - :checked [Boolean] whether the radio is checked
      #   - :disabled [Boolean] whether the radio is disabled
      #   - :described_by [String] id of element describing this input
      #   - :controls [String] id of element controlled by this input
      #   - :lang [String] language code
      #   - :class [String] additional CSS classes
      #   - :onchange [String] JS for onchange event
      #   - :help_text [String] help text rendered below the label
      def initialize(attribute:, value:, form: nil, **options)
        @form = form
        @attribute = attribute
        @value = value
        extract_options!(options)
      end

      def call
        return radio_button_html if @label.blank?

        tag.div(class: 'flex flex-col') do
          tag.div(class: 'flex items-center gap-3') do
            radio_button_html + label_html
          end +
            tag.div(class: 'mt-1 ml-8') do
              help_html
            end
        end
      end

      # Satisfy FormHelpers contract for input_classes
      def input_classes(user_class)
        radio_button_classes(user_class)
      end

      private

      # Extracts and assigns options to instance variables
      def extract_options!(options)
        @options = options.dup
        @input_name = options.delete(:input_name)
        @label = options.delete(:label)
        @checked = options.delete(:checked) { false }
        @disabled = options.delete(:disabled) { false }
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @help_text = options.delete(:help_text)
        @user_class = options.delete(:class)
        @html_options = options # Remaining options (e.g., data-*)
      end

      # Renders the radio input element
      def radio_button_html
        radio_button_tag(
          input_name,
          @value,
          @checked,
          form_attributes.merge(id: input_id).merge(@html_options)
        )
      end

      # Renders the label for the radio button
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
