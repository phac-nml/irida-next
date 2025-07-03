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

    test 'success alert has correct icon color' do
      render_inline(Viral::AlertComponent.new(message: 'Success message', type: 'success'))
      assert_text 'Success message'
      assert_selector 'div.text-green-800.border-green-300.bg-green-50', count: 1
      assert_selector 'svg.text-green-600', count: 1
    end

    test 'danger alert has correct icon color' do
      render_inline(Viral::AlertComponent.new(message: 'Danger message', type: 'danger'))
      assert_text 'Danger message'
      assert_selector 'div.text-red-800.border-red-300.bg-red-50', count: 1
      assert_selector 'svg.text-red-600', count: 1
    end

    test 'info alert has correct icon color' do
      render_inline(Viral::AlertComponent.new(message: 'Info message', type: 'info'))
      assert_text 'Info message'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
      assert_selector 'svg.text-blue-600', count: 1
    end

    test 'alert with content' do
      render_preview(:with_content)
      assert_text 'This is content for the alert'
    end
  end
end
