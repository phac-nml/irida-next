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
    class RadioButtonComponent < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper

      def initialize(form:, attribute:, value:, **options)
        @form = form
        @attribute = attribute
        @value = value
        @options = options

        # Extract common options
        @label = options.delete(:label)
        @checked = options.delete(:checked) { false }
        @disabled = options.delete(:disabled) { false }
        @required = options.delete(:required) { false }
        @invalid = options.delete(:invalid) { false }
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @lang = options.delete(:lang)
      end

      def call
        # Generate the radio button HTML directly without using form builder
        radio_button = radio_button_tag(
          "#{@form.object_name}[#{@attribute}]",
          @value,
          @checked,
          radio_button_attributes
        )

        return radio_button if @options[:raw_input]

        label = label_tag(
          radio_button_id,
          @label || @attribute.to_s.humanize,
          class: 'ml-2 text-sm font-medium text-slate-900 dark:text-slate-300',
          lang: @lang
        )

        tag.div(class: 'flex items-center') do
          safe_join([radio_button, label])
        end
      end

      private

      def radio_button_id
        @radio_button_id ||= "#{@form.object_name}_#{@attribute}_#{@value}".gsub(/[\[\]]+/, '_').chomp('_')
      end

      def radio_button_attributes
        {
          id: radio_button_id,
          disabled: @disabled,
          required: @required,
          class: radio_button_classes,
          aria: radio_button_aria_attributes
        }.compact
      end

      def radio_button_classes
        class_names(
          @options[:class],
          # Layout & Sizing
          'h-5 w-5 shrink-0 mt-0.5',
          # Shape & Border
          'rounded-full border-2 border-slate-500',
          # Colors & Background
          'text-primary-600 bg-white',
          # Cursor & Interaction
          'cursor-pointer transition-colors duration-200 ease-in-out',
          # Checked State
          'checked:border-primary-500',
          # Disabled State
          'disabled:opacity-50 disabled:cursor-not-allowed',
          'disabled:border-slate-200 disabled:bg-slate-100',
          # Dark Mode
          'dark:border-slate-600 dark:bg-slate-700',
          'dark:checked:bg-primary-600 dark:checked:border-primary-500',
          'dark:disabled:bg-slate-800 dark:disabled:border-slate-700',
          'dark:disabled:checked:bg-slate-600'
        )
      end

      def radio_button_aria_attributes
        {
          label: @label,
          disabled: @disabled.to_s,
          required: @required.to_s,
          invalid: @invalid.to_s,
          describedby: @described_by,
          controls: @controls
        }.compact
      end
    end
  end
end
