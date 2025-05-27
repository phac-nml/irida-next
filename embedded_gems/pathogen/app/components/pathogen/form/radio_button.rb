# frozen_string_literal: true

module Pathogen
  module Form
    # A custom radio button component with built-in accessibility features and styling
    #
    # @example Basic usage
    #   <%= render Pathogen::Form::RadioButtonComponent.new(
    #     form: form,
    #     attribute: :notification_preference,
    #     value: "email",
    #     label: "Email notifications"
    #   ) %>
    #
    # @example With additional options
    #   <%= render Pathogen::Form::RadioButtonComponent.new(
    #     form: form,
    #     attribute: :notification_preference,
    #     value: "sms",
    #     label: "SMS notifications",
    #     checked: true,
    #     disabled: false,
    #     required: true,
    #     described_by: "sms_help",
    #     controls: "sms_fields",
    #     lang: "en",
    #     class: "custom-class"
    #   ) %>
    class RadioButton < ViewComponent::Base
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
      #   - :invalid [Boolean] whether the radio is invalid
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

      def radio_button_html
        radio_button_tag(
          "#{@form.object_name}[#{@attribute}]",
          @value,
          @checked,
          radio_button_attributes.merge(id: radio_button_id)
        )
      end

      def label_and_help_html
        tag.div(class: 'flex flex-col') do
          label_html + help_html
        end
      end

      def label_html
        if @label.present?
          tag.label(@label, for: radio_button_id, class: label_classes)
        else
          tag.label('[No label provided]', for: radio_button_id, class: "#{label_classes} text-red-500")
        end
      end

      def help_html
        if @help_text.present?
          tag.p(@help_text, id: help_text_id, class: help_text_classes)
        else
          ''.html_safe
        end
      end

      def help_text_id
        @help_text_id ||= "#{radio_button_id}_help"
      end

      def radio_button_id
        @radio_button_id ||= "#{@form.object_name}_#{@attribute}_#{@value}".gsub(/[\[\]]+/, '_').chomp('_')
      end

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

      def radio_button_aria_attributes
        {
          label: @label,
          disabled: @disabled.to_s,
          required: @required.to_s,
          invalid: @invalid.to_s,
          describedby: @described_by,
          controls: @controls,
          checked: @checked.to_s
        }.compact
      end

      # Extracts and assigns options to instance variables
      def extract_options!(options)
        @options = options
        @label = options.delete(:label)
        @checked = options.delete(:checked) { false }
        @disabled = options.delete(:disabled) { false }
        @required = options.delete(:required) { false }
        @invalid = options.delete(:invalid) { false }
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @help_text = options.delete(:help_text)
      end
    end
  end
end
