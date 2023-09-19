# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class CheckboxComponentTest < ViewComponentTestCase
      def test_default
        render_preview(:default)
        assert_selector 'input[@type="checkbox"]', count: 1
      end

      def test_checked
        render_preview(:default_checked)
        assert_selector 'input[type="checkbox"]', count: 1
      end

      def test_checkbox_with_help_text
        render_preview(:default_with_help_text)
        assert_selector 'input[type="checkbox"]', count: 1
        assert_selector 'p.text-sm', text: 'Checkbox help text'
      end
    end
  end
end
