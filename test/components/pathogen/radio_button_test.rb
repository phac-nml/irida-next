# test/components/pathogen/form/radio_button_component_test.rb
require 'test_helper'

module Pathogen
  module Form
    class RadioButtonTest < ViewComponent::TestCase
      def test_renders_radio_button_with_basic_attributes
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme'
                      ))

        assert_selector "input[type='radio'][name='theme'][value='dark']"
        assert_selector 'label', text: 'Dark Theme'
      end

      def test_renders_radio_button_with_form_builder
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        form = ActionView::Helpers::FormBuilder.new(
          'user',
          User.new,
          template,
          {}
        )

        render_inline(RadioButton.new(
                        form: form,
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme'
                      ))

        assert_selector "input[type='radio'][name='user[theme]'][value='dark']"
        assert_selector 'label', text: 'Dark Theme'
      end

      def test_renders_radio_button_with_help_text
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme',
                        help_text: 'Follows system preferences'
                      ))

        assert_selector 'span', text: 'Follows system preferences'
        assert_selector 'input[aria-describedby]'
      end

      def test_renders_radio_button_with_custom_classes
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme',
                        class: 'custom-class'
                      ))

        assert_selector 'input.custom-class'
      end

      def test_renders_radio_button_with_checked_state
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme',
                        checked: true
                      ))

        assert_selector 'input[checked]'
      end

      def test_renders_radio_button_with_disabled_state
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme',
                        disabled: true
                      ))

        assert_selector 'input[disabled]'
      end

      def test_renders_radio_button_with_aria_attributes
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark',
                        label: 'Dark Theme',
                        described_by: 'help-text',
                        controls: 'controlled-element'
                      ))

        assert_selector "input[aria-describedby='help-text']"
        assert_selector "input[aria-controls='controlled-element']"
      end

      def test_renders_radio_button_without_label
        render_inline(RadioButton.new(
                        attribute: :theme,
                        value: 'dark'
                      ))

        assert_selector "input[type='radio']"
        assert_no_selector 'label'
      end
    end
  end
end
