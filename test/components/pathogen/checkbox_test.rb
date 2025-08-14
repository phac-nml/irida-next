# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Form
    class CheckboxTest < ViewComponent::TestCase
      def test_renders_checkbox_with_basic_attributes
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms'
                      ))

        assert_selector "input[type='checkbox'][name='terms'][value='1']"
        assert_selector 'label', text: 'I agree to the terms'
      end

      def test_renders_checkbox_with_form_builder
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        form = ActionView::Helpers::FormBuilder.new(
          'user',
          User.new,
          template,
          {}
        )

        render_inline(Checkbox.new(
                        form: form,
                        attribute: :newsletter,
                        value: '1',
                        label: 'Subscribe to newsletter'
                      ))

        assert_selector "input[type='checkbox'][name='user[newsletter]'][value='1']"
        assert_selector 'label', text: 'Subscribe to newsletter'
      end

      def test_renders_checkbox_with_help_text
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        help_text: 'You must agree to continue'
                      ))

        assert_selector 'span', text: 'You must agree to continue'
        assert_selector 'input[aria-describedby]'
      end

      def test_renders_checkbox_with_custom_classes
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        class: 'custom-class'
                      ))

        assert_selector 'input.custom-class'
      end

      def test_renders_checkbox_with_checked_state
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        checked: true
                      ))

        assert_selector 'input[checked]'
      end

      def test_renders_checkbox_with_disabled_state
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        disabled: true
                      ))

        assert_selector 'input[disabled]'
      end

      def test_renders_checkbox_with_aria_attributes
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        described_by: 'help-text',
                        controls: 'controlled-element'
                      ))

        assert_selector "input[aria-describedby='help-text']"
        assert_selector "input[aria-controls='controlled-element']"
      end

      def test_renders_checkbox_with_aria_label_only
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        aria_label: 'Terms and conditions checkbox'
                      ))

        assert_selector "input[type='checkbox']"
        assert_selector "input[aria-label='Terms and conditions checkbox']"
        assert_no_selector 'label'
      end

      def test_renders_checkbox_with_aria_label_and_help_text
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        aria_label: 'Terms and conditions checkbox',
                        help_text: 'You must agree to continue'
                      ))

        assert_selector "input[type='checkbox']"
        assert_selector "input[aria-label='Terms and conditions checkbox']"
        assert_selector 'span.sr-only', text: 'You must agree to continue'
        assert_no_selector 'label'
      end

      def test_raises_error_without_label_or_aria_label
        assert_raises ArgumentError do
          render_inline(Checkbox.new(
                          attribute: :terms,
                          value: '1'
                        ))
        end
      end

      def test_renders_checkbox_with_onchange_event
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        onchange: 'handleChange()'
                      ))

        assert_selector "input[onchange='handleChange()']"
      end

      def test_renders_checkbox_with_lang_attribute
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        lang: 'en'
                      ))

        assert_selector "input[lang='en']"
      end

      def test_renders_checkbox_with_data_attributes
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        data: { test_id: 'terms-checkbox' }
                      ))

        assert_selector "input[data-test-id='terms-checkbox']"
      end
    end
  end
end
