# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PillComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_selector 'span', count: 3
      assert_selector '.bg-purple-100.text-purple-800.text-xs.font-medium.rounded-full',
                      text: 'This has much more text and is purple'
      assert_selector '.bg-green-100.text-green-800.text-xs.font-medium.rounded-full', text: 'This is green'
      assert_selector '.bg-blue-100.text-blue-800.text-xs.font-medium.rounded-full', text: 'This is blue'
    end

    test 'with_border' do
      render_preview(:with_border)
      assert_selector 'span', count: 3
      assert_selector '.bg-purple-100.text-purple-800.text-xs.font-medium.rounded-full.border.border-purple-800',
                      text: 'This has much more text and is purple'
      assert_selector '.bg-green-100.text-green-800.text-xs.font-medium.rounded-full.border.border-green-800',
                      text: 'This is green'
      assert_selector '.bg-blue-100.text-blue-800.text-xs.font-medium.rounded-full.border.border-blue-800',
                      text: 'This is blue'
    end

    test 'with_classes' do
      render_preview(:with_classes)
      assert_selector 'span', count: 4
      assert_selector '.bg-slate-100.text-slate-800.underline', text: 'This is slate and underlined'
      assert_selector '.bg-yellow-100.text-yellow-800.line-through', text: 'This is yellow and striked through'
      assert_selector '.bg-indigo-100.text-indigo-800.overline', text: 'This is indigo and overlined'
      assert_selector '.bg-pink-100.text-pink-800.underline.decoration-wavy.decoration-black',
                      text: 'This is pink and has multiple added classes'
    end

    test 'with_content' do
      render_preview(:with_content)
      assert_selector 'span.bg-primary-100', count: 1, text: 'This is the content'
    end
  end
end
