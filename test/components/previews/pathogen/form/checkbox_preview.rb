# test/components/previews/pathogen/form/checkbox_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    class CheckboxPreview < ViewComponent::Preview
      include Pathogen::ViewHelper

      # @!group Basic Examples

      # @label Default Checkbox
      def default
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions'
        )
      end

      # @label Checkbox with Help Text
      def with_help_text
        pathogen_checkbox(
          attribute: :newsletter,
          value: '1',
          label: 'Subscribe to newsletter',
          help_text: 'Get updates about new features and announcements'
        )
      end

      # @label Checkbox with Custom Classes
      def with_custom_classes
        pathogen_checkbox(
          attribute: :marketing,
          value: '1',
          label: 'Receive marketing emails',
          class: 'custom-checkbox'
        )
      end

      # @!endgroup

      # @!group States

      # @label Checked State
      def checked
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions',
          checked: true
        )
      end

      # @label Disabled State
      def disabled
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions',
          disabled: true
        )
      end

      # @label Checked and Disabled
      def checked_and_disabled
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions',
          checked: true,
          disabled: true
        )
      end

      # @label Required State
      def required
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions *',
          required: true
        )
      end

      # @!endgroup

      # @!group Form Integration

      # @label With Form Builder
      def with_form_builder
        render_with_template(
          template: 'pathogen/form/checkbox_preview/form_builder',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @label Form Group
      def form_group
        render_with_template(
          template: 'pathogen/form/checkbox_preview/form_group',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @!endgroup

      # @!group Accessibility

      # @label With ARIA Attributes
      def with_aria_attributes
        pathogen_checkbox(
          attribute: :accessibility,
          value: '1',
          label: 'Enable accessibility features',
          described_by: 'accessibility-help',
          controls: 'accessibility-panel'
        )
      end

      # @label With Help Text and ARIA
      def with_help_text_and_aria
        pathogen_checkbox(
          attribute: :accessibility,
          value: '1',
          label: 'Enable accessibility features',
          help_text: 'Includes screen reader support and keyboard navigation',
          described_by: 'accessibility-help',
          controls: 'accessibility-panel'
        )
      end

      # @label With Language Attribute
      def with_language
        pathogen_checkbox(
          attribute: :language,
          value: 'fr',
          label: 'Français',
          lang: 'fr'
        )
      end

      # @!endgroup

      # @!group Edge Cases

      # @label Without Label
      def without_label
        pathogen_checkbox(
          attribute: :hidden_option,
          value: '1'
        )
      end

      # @label With Long Label
      def with_long_label
        pathogen_checkbox(
          attribute: :complex_terms,
          value: '1',
          label: 'I acknowledge that I have read, understood, and agree to be bound by all the terms and conditions, privacy policy, and any other agreements that may be applicable to my use of this service'
        )
      end

      # @label With Special Characters
      def with_special_characters
        pathogen_checkbox(
          attribute: :special_option,
          value: '1',
          label: 'Special Option (Recommended) ⭐ 🚀'
        )
      end

      # @label With Error Text
      def with_error_text
        pathogen_checkbox(
          attribute: :terms,
          value: '1',
          label: 'I agree to the terms and conditions',
          error_text: 'You must agree to the terms to continue'
        )
      end

      # @!endgroup

      # @!group Interactive Examples

      # @label Interactive Group
      def interactive_group
        render_with_template(
          template: 'pathogen/form/checkbox_preview/interactive_group',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @label Multiple Checkboxes
      def multiple_checkboxes
        render_with_template(
          template: 'pathogen/form/checkbox_preview/multiple_checkboxes',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @!endgroup

      # @!group Real-world Examples

      # @label User Preferences
      def user_preferences
        render_with_template(
          template: 'pathogen/form/checkbox_preview/user_preferences',
          locals: {
            form: mock_form_builder
          }
        )
      end

      # @label Terms and Conditions
      def terms_and_conditions
        render_with_template(
          template: 'pathogen/form/checkbox_preview/terms_and_conditions',
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
          'form',
          {},
          template,
          {}
        )
      end
    end
  end
end
