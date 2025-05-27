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
        @onchange = options.delete(:onchange)
        @help_text = options.delete(:help_text)
      end

      def call
        tag.div(class: 'flex items-start gap-3') do
          # Generate the radio button HTML with explicit ID
          radio = radio_button_tag(
            "#{@form.object_name}[#{@attribute}]",
            @value,
            @checked,
            radio_button_attributes.merge(id: radio_button_id)
          )

          # Add the label with matching ID
          label_html = if @label.present?
                         tag.label(@label, for: radio_button_id, class: label_classes)
                       else
                         tag.label('[No label provided]', for: radio_button_id, class: label_classes + ' text-red-500')
                       end

          help_html = if @help_text.present?
                        tag.p(@help_text, id: help_text_id, class: help_text_classes)
                      else
                        ''.html_safe
                      end

          # Wrap label and help text in a div for vertical stacking
          label_and_help = tag.div(class: 'flex flex-col') do
            label_html + help_html
          end

          # Return the combined HTML
          radio + label_and_help
        end
      end

      private

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

      def radio_button_classes
        class_names(
          @options[:class],
          # Layout & Sizing
          'h-5 w-5 shrink-0 mt-0.5',
          # Shape & Border
          'rounded-full border-2',
          # Colors & Background
          'text-primary-600 bg-white',
          # Focus States
          'focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2',
          # Cursor & Interaction
          'cursor-pointer transition-colors duration-200 ease-in-out',
          # Checked State
          'checked:border-primary-500 checked:bg-primary-500',
          # Hover State
          'hover:border-primary-500',
          # Disabled State
          'disabled:opacity-50 disabled:cursor-not-allowed',
          'disabled:border-slate-200 disabled:bg-slate-100',
          # Dark Mode
          'dark:border-slate-600 dark:bg-slate-700',
          'dark:checked:bg-primary-600 dark:checked:border-primary-500',
          'dark:disabled:bg-slate-800 dark:disabled:border-slate-700',
          'dark:disabled:checked:bg-slate-600',
          'dark:focus:ring-primary-400'
        )
      end

      def label_classes
        class_names(
          # Typography
          'text-sm font-medium text-slate-900',
          # Cursor
          'cursor-pointer',
          # Disabled State
          'disabled:cursor-not-allowed disabled:opacity-50',
          # Dark Mode
          'dark:text-slate-100'
        )
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

      def help_text_classes
        'text-sm text-slate-500 mt-1 dark:text-slate-400'
      end
    end
  end
end
