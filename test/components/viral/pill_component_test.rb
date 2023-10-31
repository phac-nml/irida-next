# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PillComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)

      assert_selector 'span.bg-blue-100'
      assert_selector 'span.bg-green-100'
      assert_selector 'span.bg-purple-100'

      assert_selector '.rounded-full', count: 3

      assert_text 'This is blue'
      assert_text 'This is green'
      assert_text 'This has much more text and is purple'
    end
  end
end
