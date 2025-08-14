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
        # aria-describedby should not be present unless help_text or described_by is provided
        assert_no_selector 'input[aria-describedby]'
      end

      def test_renders_checkbox_with_form_builder # rubocop:disable Metrics/MethodLength
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
        # aria-describedby should not be present unless help_text or described_by is provided
        assert_no_selector 'input[aria-describedby]'
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
        assert_selector "input[aria-describedby*='#{help_text_id_for(:terms, '1')}']"
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

        assert_selector "input[aria-describedby*='help-text']"
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
        assert_selector 'div.flex.flex-col'
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
        assert_selector 'div.flex.flex-col'
      end

      def test_renders_checkbox_with_aria_label_and_controls
        render_inline(Checkbox.new(
                        attribute: :select_all,
                        value: '1',
                        aria_label: 'Select all items',
                        controls: 'items-table',
                        help_text: 'Selects all items on the page'
                      ))

        assert_selector "input[aria-controls='items-table']"
        assert_selector "input[aria-label='Select all items']"
        assert_selector 'span.sr-only', text: 'Selects all items on the page'
      end

      def test_renders_checkbox_with_aria_live
        render_inline(Checkbox.new(
                        attribute: :select_all,
                        value: '1',
                        aria_label: 'Select all items',
                        aria_live: 'polite'
                      ))

        assert_selector "input[aria-live='polite']"
      end

      def test_renders_checkbox_with_role
        render_inline(Checkbox.new(
                        attribute: :select_all,
                        value: '1',
                        aria_label: 'Select all items',
                        role: 'button'
                      ))

        assert_selector "input[role='button']"
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

        # The component does not currently apply 'lang' to the input element
        assert_selector "input[type='checkbox']"
        assert_no_selector 'input[lang]'
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

      def test_renders_checkbox_with_html_options
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        title: 'custom-value'
                      ))

        # Arbitrary top-level HTML attributes should be applied to the input
        assert_selector "input[title='custom-value']"
      end

      def test_raises_error_without_label_or_aria_label
        assert_raises ArgumentError, "Checkbox requires either 'label' or 'aria_label' for accessibility compliance" do
          render_inline(Checkbox.new(
                          attribute: :terms,
                          value: '1'
                        ))
        end
      end

      def test_raises_error_with_empty_label_and_aria_label
        assert_raises ArgumentError, "Checkbox requires either 'label' or 'aria_label' for accessibility compliance" do
          render_inline(Checkbox.new(
                          attribute: :terms,
                          value: '1',
                          label: '',
                          aria_label: ''
                        ))
        end
      end

      def test_renders_enhanced_description_for_select_all
        render_inline(Checkbox.new(
                        attribute: :select_all,
                        value: '1',
                        aria_label: 'Select all items',
                        controls: 'items-table'
                      ))

        assert_selector 'span#select_all_1_description.sr-only'
        assert_selector 'span[aria-live="polite"]'
      end

      def test_renders_enhanced_description_for_select_page
        render_inline(Checkbox.new(
                        attribute: :select_page,
                        value: '1',
                        aria_label: 'Select page items',
                        controls: 'items-table'
                      ))

        assert_selector 'span#select_page_1_description.sr-only'
        assert_selector 'span[aria-live="polite"]'
      end

      def test_renders_enhanced_description_for_select_row
        render_inline(Checkbox.new(
                        attribute: :select_row,
                        value: '1',
                        aria_label: 'Select row item',
                        controls: 'items-table'
                      ))

        assert_selector 'span#select_row_1_description.sr-only'
        assert_selector 'span[aria-live="polite"]'
      end

      def test_does_not_render_enhanced_description_for_other_attributes
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        aria_label: 'Terms checkbox',
                        controls: 'terms-panel'
                      ))

        assert_no_selector 'span#terms_1_description'
      end

      def test_renders_labeled_checkbox_layout
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms'
                      ))

        assert_selector 'div.flex.flex-col'
        assert_selector 'div.flex.items-center.gap-3'
        assert_selector 'div.mt-1.ml-8'
      end

      def test_renders_aria_only_checkbox_layout
        render_inline(Checkbox.new(
                        attribute: :select_all,
                        value: '1',
                        aria_label: 'Select all items'
                      ))

        assert_selector 'div.flex.flex-col'
        assert_selector 'div.mt-1'
        assert_no_selector 'div.flex.items-center.gap-3'
        assert_no_selector 'div.mt-1.ml-8'
      end

      def test_generates_correct_input_id
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms'
                      ))

        expected_id = 'terms_1'
        assert_selector "input##{expected_id}"
        assert_selector "label[for='#{expected_id}']"
      end

      def test_generates_correct_input_id_with_form
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

        expected_id = 'user_newsletter_1'
        assert_selector "input##{expected_id}"
        assert_selector "label[for='#{expected_id}']"
      end

      def test_generates_correct_help_text_id
        render_inline(Checkbox.new(
                        attribute: :terms,
                        value: '1',
                        label: 'I agree to the terms',
                        help_text: 'You must agree to continue'
                      ))

        expected_help_id = 'terms_1_help'
        assert_selector "span##{expected_help_id}"
        assert_selector "input[aria-describedby*='#{expected_help_id}']"
      end

      def test_handles_array_attribute_names
        render_inline(Checkbox.new(
                        attribute: 'sample_ids[]',
                        value: '1',
                        aria_label: 'Select sample'
                      ))

        assert_selector "input[name='sample_ids[]']"
        assert_selector "input[aria-label='Select sample']"
      end

      def test_handles_special_characters_in_attribute_names
        render_inline(Checkbox.new(
                        attribute: 'user[preferences][newsletter]',
                        value: '1',
                        aria_label: 'Newsletter preference'
                      ))

        assert_selector "input[name='user[preferences][newsletter]']"
        assert_selector "input[aria-label='Newsletter preference']"
      end

      private

      def help_text_id_for(attribute, value)
        "#{attribute}_#{value}_help"
      end
    end
  end
end
