# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class TextInputComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)

        assert_selector 'label', text: 'Test input label'
        assert_selector 'input[type="text"]', count: 1
      end

      test 'helper text' do
        render_preview(:default_with_help_text)

        assert_selector 'label', text: 'Text input with help'
        assert_selector 'input[type="text"]', count: 1
        assert_selector 'p.text-sm', text: 'Text input with help text content'
      end

      test 'number input' do
        render_preview(:number_input)

        assert_selector 'label', text: 'Number input label'
        assert_selector 'input[type="number"]', count: 1
      end
    end
  end
end
