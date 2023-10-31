# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PillComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_selector 'span', count: 3
      assert_selector '.bg-purple-100.text-purple-800', text: 'This has much more text and is purple'
      assert_selector '.bg-green-100.text-green-800', text: 'This is green'
      assert_selector '.bg-blue-100.text-blue-800', text: 'This is blue'
      assert_selector '.text-xs.font-medium.mr-2.rounded-full', count: 3
    end

    test 'with_classes' do
      render_preview(:with_classes)
      assert_selector 'span', count: 3
      assert_selector 'span.underline', text: 'This is blue and underlined'
      assert_selector 'span.line-through', text: 'This is green and striked through'
      assert_selector 'span.overline', text: 'This is purple and overlined'
    end
  end
end
