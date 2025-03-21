# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class DatepickerComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)
        assert_no_selector 'label'
        assert_selector 'input[type="text"]', count: 1
        assert_selector '.viral-icon', count: 1
      end

      test 'with label' do
        render_preview(:with_label)
        assert_selector 'label', text: 'Pick a date'
        assert_selector 'input[type="text"]', count: 1
        assert_selector '.viral-icon', count: 1
      end

      test 'with help text' do
        render_preview(:with_help_text)
        assert_no_selector 'label'
        assert_selector 'input[type="text"]', count: 1
        assert_selector 'p.text-sm', text: 'Select a date in the future'
      end

      test 'with placeholder' do
        render_preview(:with_placeholder)
        assert_no_selector 'label'
        assert_selector 'input[type="text"][placeholder="Pick a date"]', count: 1
      end
    end
  end
end
