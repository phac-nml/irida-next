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
          'preview',
          :terms,
          { label: 'I agree to the terms and conditions' },
          '1',
          '0'
        )
      end

      # @label Checkbox with Help Text
      def with_help_text
        pathogen_checkbox(
          'preview',
          :newsletter,
          {
            label: 'Subscribe to newsletter',
            help_text: 'Get updates about new features and announcements'
          },
          '1',
          '0'
        )
      end

      # @label Checkbox with Custom Classes
      def with_custom_classes
        pathogen_checkbox(
          'preview',
          :marketing,
          {
            label: 'Receive marketing emails',
            class: 'custom-checkbox'
          },
          '1',
          '0'
        )
      end

      # @!endgroup

      # @!group States

      # @label Checked State
      def checked
        pathogen_checkbox(
          'preview',
          :terms,
          {
            label: 'I agree to the terms and conditions',
            checked: true
          },
          '1',
          '0'
        )
      end

      # @label Disabled State
      def disabled
        pathogen_checkbox(
          'preview',
          :terms,
          {
            label: 'I agree to the terms and conditions',
            disabled: true
          },
          '1',
          '0'
        )
      end

      # @label Checked and Disabled
      def checked_and_disabled
        pathogen_checkbox(
          'preview',
          :terms,
          {
            label: 'I agree to the terms and conditions',
            checked: true,
            disabled: true
          },
          '1',
          '0'
        )
      end

      # @label Required State
      def required
        pathogen_checkbox(
          'preview',
          :terms,
          {
            label: 'I agree to the terms and conditions *',
            required: true
          },
          '1',
          '0'
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
          'preview',
          :accessibility,
          {
            label: 'Enable accessibility features',
            aria: {
              describedby: 'accessibility-help',
              controls: 'accessibility-panel'
            }
          },
          '1',
          '0'
        )
      end

      # @label With Help Text and ARIA
      def with_help_text_and_aria
        pathogen_checkbox(
          'preview',
          :accessibility,
          {
            label: 'Enable accessibility features',
            help_text: 'Includes screen reader support and keyboard navigation',
            aria: {
              describedby: 'accessibility-help',
              controls: 'accessibility-panel'
            }
          },
          '1',
          '0'
        )
      end

      # @label With Language Attribute
      def with_language
        pathogen_checkbox(
          'preview',
          :language,
          { label: 'Français', lang: 'fr' },
          'fr',
          '0'
        )
      end

      # @label With ARIA Labelledby
      def with_aria_labelledby
        render_with_template(
          template: 'pathogen/form/checkbox_preview/with_aria_labelledby'
        )
      end

      # @!endgroup

      # @!group WCAG Accessibility Examples

      # @label Select All Checkbox (Common Pattern)
      def select_all_checkbox
        pathogen_checkbox(
          'preview',
          :select_all,
          {
            aria: {
              label: 'Select all samples on this page',
              controls: 'samples-table-body',
              live: 'polite'
            },
            help_text: 'Check to select all samples, uncheck to deselect all'
          },
          '1',
          '0'
        )
      end

      # @label Row Selection Checkbox
      def row_selection_checkbox
        pathogen_checkbox(
          'preview',
          :select_row,
          {
            aria: {
              label: 'Select sample SAMPLE-001',
              controls: 'sample-details-panel'
            },
            help_text: 'Check to select this sample, uncheck to deselect'
          },
          '1',
          '0'
        )
      end

      # @label Form Checkbox with Enhanced ARIA
      def form_checkbox_with_enhanced_aria
        pathogen_checkbox(
          'preview',
          :accessibility,
          {
            label: 'Enable accessibility features',
            aria: {
              describedby: 'accessibility-help',
              controls: 'accessibility-panel'
            },
            help_text: 'Includes screen reader support and keyboard navigation'
          },
          '1',
          '0'
        )
      end

      # @!endgroup

      # @!group Edge Cases

      # @label With Aria Label Only (No Visible Label)
      def with_aria_label_only
        pathogen_checkbox(
          'preview',
          :hidden_option,
          {
            aria: {
              label: 'Hidden option checkbox for screen readers'
            }
          },
          '1',
          '0'
        )
      end

      # @label With Aria Label and Help Text (No Visible Label)
      def with_aria_label_and_help_text
        pathogen_checkbox(
          'preview',
          :select_all,
          {
            aria: {
              label: 'Select all items on this page'
            },
            help_text: 'Check to select all items, uncheck to deselect all'
          },
          '1',
          '0'
        )
      end

      # @label With Long Label
      def with_long_label
        pathogen_checkbox(
          'preview',
          :complex_terms,
          {
            label:
              'I acknowledge that I have read, understood, and agree to be bound by all the terms and ' \
              'conditions, privacy policy, and any other agreements that may be applicable to my use of ' \
              'this service'
          },
          '1',
          '0'
        )
      end

      # @label With Special Characters
      def with_special_characters
        pathogen_checkbox(
          'preview',
          :special_option,
          { label: 'Special Option (Recommended) ⭐ 🚀' },
          '1',
          '0'
        )
      end

      # @label With Error Text
      def with_error_text
        pathogen_checkbox(
          'preview',
          :terms,
          {
            label: 'I agree to the terms and conditions',
            error_text: 'You must agree to the terms to continue'
          },
          '1',
          '0'
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
