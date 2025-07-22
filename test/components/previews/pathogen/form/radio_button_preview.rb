# test/components/previews/pathogen/form/radio_button_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    class RadioButtonPreview < ViewComponent::Preview
      # @!group Basic Examples

      # @label Default Radio Button
      def default
        render pathogen_radio_button(
          attribute: :theme,
          value: 'light',
          label: 'Light Theme'
        )
      end

      # @label Radio Button with Help Text
      def with_help_text
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          help_text: 'Follows your system preferences'
        )
      end

      # @label Radio Button with Custom Classes
      def with_custom_classes
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'system',
          label: 'System Theme',
          class: 'custom-radio-button'
        )
      end

      # @!endgroup

      # @!group States

      # @label Checked State
      def checked
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          checked: true
        )
      end

      # @label Disabled State
      def disabled
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          disabled: true
        )
      end

      # @label Checked and Disabled
      def checked_and_disabled
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          checked: true,
          disabled: true
        )
      end

      # @!endgroup

      # @!group Form Integration

      # @label With Form Builder
      def with_form_builder
        render_with_template(
          template: 'pathogen/form/radio_button_preview/form_builder',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @label Form Group
      def form_group
        render_with_template(
          template: 'pathogen/form/radio_button_preview/form_group',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @!endgroup

      # @!group Accessibility

      # @label With ARIA Attributes
      def with_aria_attributes
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          described_by: 'theme-help',
          controls: 'theme-panel'
        )
      end

      # @label With Help Text and ARIA
      def with_help_text_and_aria
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          help_text: 'Follows system preferences',
          described_by: 'theme-help',
          controls: 'theme-panel'
        )
      end

      # @!endgroup

      # @!group Edge Cases

      # @label Without Label
      def without_label
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark'
        )
      end

      # @label With Long Label
      def with_long_label
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'This is a very long label that might wrap to multiple lines and should be handled gracefully by the component'
        )
      end

      # @label With Special Characters
      def with_special_characters
        render ::Pathogen::Form::RadioButton.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme (Recommended) ⭐'
        )
      end

      # @!endgroup

      # @!group Interactive Examples

      # @label Interactive Group
      def interactive_group
        render_with_template(
          template: 'pathogen/form/radio_button_preview/interactive_group',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @!endgroup

      private

      def mock_form_builder
        # Create a mock form builder for previews
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        ActionView::Helpers::FormBuilder.new(
          'user',
          User.new,
          template,
          {}
        )
      end
    end
  end
end
