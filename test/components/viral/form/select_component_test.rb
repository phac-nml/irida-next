# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class SelectComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)
        assert_selector 'label', text: 'Select Input'
        assert_selector 'option', count: 4
      end

      test 'default option' do
        render_preview(:selected_option)
        assert_selector 'label', text: 'Select Input'
        assert_selector 'option', count: 3
        assert_selector 'option[value="2"][selected]', count: 1
      end

      test 'with help text' do
        render_preview(:with_help_text)
        assert_selector 'label', text: 'Select Input'
        assert_selector 'option', count: 3
        assert_selector 'p.text-sm', text: 'This is a help text'
      end
    end
  end
end
