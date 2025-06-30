# test/components/previews/pathogen/form/radio_button_component_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    class RadioButtonComponentPreview < ViewComponent::Preview
      # @!group Basic Examples

      # @label Default Radio Button
      def default
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'light',
          label: 'Light Theme'
        )
      end

      # @label Radio Button with Help Text
      def with_help_text
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          help_text: 'Follows your system preferences'
        )
      end

      # @label Radio Button with Custom Classes
      def with_custom_classes
        render ::Pathogen::Form::RadioButtonComponent.new(
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
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          checked: true
        )
      end

      # @label Disabled State
      def disabled
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          disabled: true
        )
      end

      # @label Checked and Disabled
      def checked_and_disabled
        render ::Pathogen::Form::RadioButtonComponent.new(
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
          template: 'pathogen/form/radio_button_component_preview/form_builder',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @label Form Group
      # @description Multiple radio buttons in a form group
      def form_group
        render_with_template(
          template: 'pathogen/form/radio_button_component_preview/form_group',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @!endgroup

      # @!group Accessibility

      # @label With ARIA Attributes
      # @description Radio button with ARIA attributes for accessibility
      def with_aria_attributes
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme',
          described_by: 'theme-help',
          controls: 'theme-panel'
        )
      end

      # @label With Help Text and ARIA
      # @description Radio button with help text and ARIA attributes
      def with_help_text_and_aria
        render ::Pathogen::Form::RadioButtonComponent.new(
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
      # @description Radio button without a label
      def without_label
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark'
        )
      end

      # @label With Long Label
      # @description Radio button with a very long label text
      def with_long_label
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'This is a very long label that might wrap to multiple lines and should be handled gracefully by the component'
        )
      end

      # @label With Special Characters
      # @description Radio button with special characters in label
      def with_special_characters
        render ::Pathogen::Form::RadioButtonComponent.new(
          attribute: :theme,
          value: 'dark',
          label: 'Dark Theme (Recommended) ⭐'
        )
      end

      # @!endgroup

      # @!group Interactive Examples

      # @label Interactive Group
      # @description Interactive radio button group with different states
      def interactive_group
        render_with_template(
          template: 'pathogen/form/radio_button_component_preview/interactive_group',
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
