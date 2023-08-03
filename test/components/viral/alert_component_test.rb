# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class AlertComponentTest < ViewComponentTestCase
    test 'notice alert' do
      render_inline(Viral::AlertComponent.new(message: 'This is a notice alert', type: 'notice'))
      assert_text 'This is a notice alert'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
    end

    test 'alert alert' do
      render_inline(Viral::AlertComponent.new(message: 'This is an alert alert', type: 'alert'))
      assert_text 'This is an alert alert'
      assert_selector 'div.text-red-800.border-red-300.bg-red-50', count: 1
    end
  end
end
