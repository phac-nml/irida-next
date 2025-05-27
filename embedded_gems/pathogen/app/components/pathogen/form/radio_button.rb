# frozen_string_literal: true

# 🟢 Pathogen::Form::RadioButtonComponent 🟢
#
# 🎯 Purpose:
#   This file defines a custom, accessible, and beautifully styled radio button component for Rails forms.
#   - Designed for maximum accessibility (ARIA, labels, help text)
#   - Uses Tailwind CSS for modern, responsive styling
#   - Easy to use and extend in your Rails app
#
# 🚀 Usage Example:
#   <%= render Pathogen::Form::RadioButtonComponent.new(
#     form: form,                      # 📝 Your form builder
#     attribute: :theme,               # 🏷️  The model attribute
#     value: "system",                # 💾 The value for this radio
#     label: "System",                # 🏷️  The label shown to users
#     help_text: "Theme follows your OS settings." # 💡 Optional help text
#   ) %>
#
# 🧩 Options:
#   - :label        🏷️   (String)   — The label text shown next to the radio
#   - :checked      ✅   (Boolean)   — Whether this radio is selected
#   - :disabled     🚫   (Boolean)   — Whether this radio is disabled
#   - :required     ❗   (Boolean)   — Whether this radio is required
#   - :described_by 🗣️   (String)   — ID of element describing this input
#   - :controls     🎛️   (String)   — ID of element controlled by this input
#   - :lang         🌐   (String)   — Language code
#   - :class        🎨   (String)   — Extra CSS classes
#   - :onchange     🔄   (String)   — JS for onchange event
#   - :help_text    💡   (String)   — Help text below the label (ARIA described)
#
# ♿ Accessibility:
#   - Associates label and input for screen readers
#   - Uses aria-describedby for help text
#   - Keyboard and screen reader friendly
#   - Visible focus and checked states
#
# 🛠️  How it works:
#   - Renders a radio input and label side-by-side
#   - Optionally renders help text below the label
#   - All ARIA and accessibility attributes are set automatically
#   - Styles are applied using Tailwind CSS utility classes
#
# 📚 See also:
#   - Pathogen::Form::RadioButtonStyles for style helpers
#
# ✨ Enjoy accessible, beautiful forms!

module Pathogen
  module Form
    # 🟢 Pathogen::Form::RadioButtonComponent 🟢
    #
    # This component renders a single radio button with a label and optional help text.
    # It is designed for accessibility and modern UI using Tailwind CSS.
    #
    # See the top of this file for full usage and options! 🎉
    class RadioButtonComponent < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
      include RadioButtonStyles

      # @param form [ActionView::Helpers::FormBuilder] the form builder
      # @param attribute [Symbol] the attribute for the radio button
      # @param value [String] the value for the radio button
      # @param options [Hash] additional options:
      #   - :label [String] the label text
      #   - :checked [Boolean] whether the radio is checked
      #   - :disabled [Boolean] whether the radio is disabled
      #   - :required [Boolean] whether the radio is required
      #   - :described_by [String] id of element describing this input
      #   - :controls [String] id of element controlled by this input
      #   - :lang [String] language code
      #   - :class [String] additional CSS classes
      #   - :onchange [String] JS for onchange event
      #   - :help_text [String] help text rendered below the label
      def initialize(form:, attribute:, value:, **options)
        @form = form
        @attribute = attribute
        @value = value
        extract_options!(options)
      end

      def call
        tag.div(class: 'flex items-start gap-3') do
          radio_button_html + label_and_help_html
        end
      end

      private

      # Extracts and assigns options to instance variables
      def extract_options!(options)
        @options = options
        @label = options.delete(:label)
        @checked = options.delete(:checked) { false }
        @disabled = options.delete(:disabled) { false }
        @required = options.delete(:required) { false }
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @help_text = options.delete(:help_text)
      end

      # Renders the radio input element
      def radio_button_html
        radio_button_tag(
          "#{@form.object_name}[#{@attribute}]",
          @value,
          @checked,
          radio_button_attributes.merge(id: radio_button_id)
        )
      end

      # Renders the label and help text stacked vertically
      def label_and_help_html
        tag.div(class: 'flex flex-col') do
          label_html + help_html
        end
      end

      # Renders the label for the radio button
      def label_html
        if @label.present?
          tag.label(@label, for: radio_button_id, class: label_classes)
        else
          tag.label('[No label provided]', for: radio_button_id, class: "#{label_classes} text-red-500")
        end
      end

      # Renders the help text below the label, if present
      def help_html
        if @help_text.present?
          tag.p(@help_text, id: help_text_id, class: help_text_classes)
        else
          ''.html_safe
        end
      end

      # Generates a unique ID for the help text
      def help_text_id
        @help_text_id ||= "#{radio_button_id}_help"
      end

      # Generates a unique ID for the radio button
      def radio_button_id
        @radio_button_id ||= "#{@form.object_name}_#{@attribute}_#{@value}".gsub(/[\[\]]+/, '_').chomp('_')
      end

      # Returns a hash of HTML attributes for the radio input
      def radio_button_attributes
        describedby = [@described_by, (@help_text.present? ? help_text_id : nil)].compact.join(' ')
        {
          disabled: @disabled,
          required: @required,
          class: radio_button_classes,
          aria: radio_button_aria_attributes.merge(describedby: describedby.presence),
          role: 'radio',
          tabindex: @disabled ? -1 : 0,
          onchange: @onchange
        }.compact
      end

      # Returns a hash of ARIA attributes for the radio input
      def radio_button_aria_attributes
        {
          label: @label,
          disabled: @disabled.to_s,
          required: @required.to_s,
          describedby: @described_by,
          controls: @controls,
          checked: @checked.to_s
        }.compact
      end
    end
  end
end
