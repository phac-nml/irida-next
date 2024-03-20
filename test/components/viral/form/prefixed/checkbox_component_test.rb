# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class PrefixedCheckboxComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)
        assert_selector 'span.font-mono', text: '--prefix', count: 1
        assert_selector 'input[type="checkbox"]', count: 1
        assert_selector 'label', text: 'Checkbox Label', count: 1
      end

      test 'with_icon' do
        render_preview(:with_icon)
        assert_selector 'span.Viral-Icon.Viral-Icon--colorWarning', count: 1
        assert_selector 'input[type="checkbox"]', count: 1
        assert_selector 'label', text: 'Checkbox Label', count: 1
      end
    end
  end
end
