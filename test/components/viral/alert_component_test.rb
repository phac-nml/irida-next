# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class AlertComponentTest < ViewComponentTestCase
    test 'notice alert' do
      render_inline(Viral::AlertComponent.new(message: 'This is a notice alert', type: 'notice'))
      assert_text 'This is a notice alert'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
      assert_selector '[role="alert"]', count: 1
      assert_selector '[aria-live="assertive"]', count: 1
      assert_selector '[aria-atomic="true"]', count: 1
    end

    test 'alert alert' do
      render_inline(Viral::AlertComponent.new(message: 'This is an alert alert', type: 'alert'))
      assert_text 'This is an alert alert'
      assert_selector 'div.text-red-800.border-red-300.bg-red-50', count: 1
      assert_selector '[role="alert"]', count: 1
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

    test 'warning alert has correct styling' do
      render_inline(Viral::AlertComponent.new(message: 'Warning message', type: 'warning'))
      assert_text 'Warning message'
      assert_selector 'div.text-amber-800.border-amber-300.bg-amber-50', count: 1
      assert_selector 'svg.text-yellow-600', count: 1
    end

    test 'alert with content' do
      render_preview(:with_content)
      assert_text 'This is content for the alert'
    end

    test 'dismissible alert has close button' do
      render_inline(Viral::AlertComponent.new(message: 'Dismissible alert', dismissible: true))
      assert_selector 'button[data-action="viral--alert#dismiss"]', count: 1
      assert_selector 'button[aria-label="Close"]', count: 1
    end

    test 'non-dismissible alert has no close button' do
      render_inline(Viral::AlertComponent.new(message: 'Non-dismissible alert', dismissible: false))
      assert_no_selector 'button[data-action="viral--alert#dismiss"]'
    end

    test 'auto-dismiss alert has progress bar' do
      render_inline(Viral::AlertComponent.new(message: 'Auto-dismiss alert', auto_dismiss: true))
      assert_selector '[data-viral--alert-target="progressBar"]', count: 1
    end

    test 'alert has correct data attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Test alert', type: 'info', dismissible: true,
                                              auto_dismiss: false))
      assert_selector '[data-controller="viral--alert"]', count: 1
      assert_selector '[data-viral--alert-dismissible-value="true"]', count: 1
      assert_selector '[data-viral--alert-auto-dismiss-value="false"]', count: 1
      assert_selector '[data-viral--alert-type-value="info"]', count: 1
    end

    test 'alert has unique IDs' do
      render_inline(Viral::AlertComponent.new(message: 'Test alert', type: 'success'))
      assert_selector '[data-viral--alert-alert-id-value]', count: 1
      assert_selector '[data-viral--alert-dismiss-button-id-value]', count: 1
    end

    test 'alert has proper icon names' do
      render_inline(Viral::AlertComponent.new(message: 'Success alert', type: 'success', dismissible: true))
      assert_selector 'svg', count: 2 # Should have check circle icon + close button

      render_inline(Viral::AlertComponent.new(message: 'Danger alert', type: 'danger', dismissible: true))
      assert_selector 'svg', count: 2 # Should have x circle icon + close button

      render_inline(Viral::AlertComponent.new(message: 'Info alert', type: 'info', dismissible: true))
      assert_selector 'svg', count: 2 # Should have info icon + close button

      render_inline(Viral::AlertComponent.new(message: 'Warning alert', type: 'warning', dismissible: true))
      assert_selector 'svg', count: 2 # Should have warning circle icon + close button
    end
  end
end
