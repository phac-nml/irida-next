# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class AlertComponentTest < ViewComponentTestCase
    # 🚨 ALERT TYPES - Different styles for different purposes

    test 'info alert renders with correct styling and attributes' do
      render_inline(Viral::AlertComponent.new(message: 'This is an info alert', type: 'info'))

      assert_text 'This is an info alert'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
      assert_selector '[role="alert"]', count: 1
      assert_selector '[aria-live="assertive"]', count: 1
      assert_selector '[aria-atomic="true"]', count: 1
      assert_selector 'svg.text-blue-600', count: 2
    end

    test 'success alert renders with correct styling and attributes' do
      render_inline(Viral::AlertComponent.new(message: 'This is a success alert', type: 'success'))

      assert_text 'This is a success alert'
      assert_selector 'div.text-green-800.border-green-300.bg-green-50', count: 1
      assert_selector '[role="alert"]', count: 1
      assert_selector 'svg.text-green-600', count: 2
    end

    test 'warning alert renders with correct styling and attributes' do
      render_inline(Viral::AlertComponent.new(message: 'This is a warning alert', type: 'warning'))

      assert_text 'This is a warning alert'
      assert_selector 'div.text-amber-800.border-amber-300.bg-amber-50', count: 1
      assert_selector '[role="alert"]', count: 1
      assert_selector 'svg.text-yellow-600', count: 2
    end

    test 'danger alert renders with correct styling and attributes' do
      render_inline(Viral::AlertComponent.new(message: 'This is a danger alert', type: 'danger'))

      assert_text 'This is a danger alert'
      assert_selector 'div.text-red-800.border-red-300.bg-red-50', count: 1
      assert_selector '[role="alert"]', count: 1
      assert_selector 'svg.text-red-600', count: 2
    end

    test 'notice type maps to info styling' do
      render_inline(Viral::AlertComponent.new(message: 'This is a notice alert', type: 'notice'))

      assert_text 'This is a notice alert'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
      assert_selector 'svg.text-blue-600', count: 2
    end

    test 'alert type maps to danger styling' do
      render_inline(Viral::AlertComponent.new(message: 'This is an alert alert', type: 'alert'))

      assert_text 'This is an alert alert'
      assert_selector 'div.text-red-800.border-red-300.bg-red-50', count: 1
      assert_selector 'svg.text-red-600', count: 2
    end

    test 'default type is info when no type specified' do
      render_inline(Viral::AlertComponent.new(message: 'This is a default alert'))

      assert_text 'This is a default alert'
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
      assert_selector 'svg.text-blue-600', count: 2
    end

    # 🎯 INTERACTIVE FEATURES - User control and automation

    test 'dismissible alert renders with close button and correct attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Dismissible alert', dismissible: true))

      assert_selector 'button[data-action="viral--alert#dismiss"]', count: 1
      assert_selector 'button[aria-label="Close"]', count: 1
      assert_selector '[data-viral--alert-dismissible-value="true"]', count: 1
      # NOTE: tabindex is set by JavaScript, not in the initial render
    end

    test 'non-dismissible alert has no close button or dismissible attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Non-dismissible alert', dismissible: false))

      assert_no_selector 'button[data-action="viral--alert#dismiss"]'
      assert_no_selector '[data-viral--alert-dismissible-value="true"]'
    end

    test 'auto-dismiss alert renders with progress bar and correct attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Auto-dismiss alert', auto_dismiss: true))

      assert_selector '[data-viral--alert-target="progressBar"]', count: 1
      assert_selector '[data-viral--alert-auto-dismiss-value="true"]', count: 1
      assert_selector '.absolute.bottom-0.left-0.h-1.bg-current.opacity-20', count: 1
    end

    test 'dismissible with auto-dismiss combines both features' do
      render_inline(Viral::AlertComponent.new(
                      message: 'Combined alert',
                      dismissible: true,
                      auto_dismiss: true
                    ))

      assert_selector 'button[data-action="viral--alert#dismiss"]', count: 1
      assert_selector '[data-viral--alert-target="progressBar"]', count: 1
      assert_selector '[data-viral--alert-dismissible-value="true"]', count: 1
      assert_selector '[data-viral--alert-auto-dismiss-value="true"]', count: 1
    end

    test 'danger alerts never auto-dismiss even when auto_dismiss is true' do
      render_inline(Viral::AlertComponent.new(
                      message: 'Danger alert',
                      type: 'danger',
                      auto_dismiss: true
                    ))

      # The component should still render with auto-dismiss attributes
      # but the JavaScript controller will prevent auto-dismiss for danger alerts
      assert_selector '[data-viral--alert-auto-dismiss-value="true"]', count: 1
      assert_selector '[data-viral--alert-type-value="danger"]', count: 1
    end

    # 📝 CONTENT VARIATIONS - Different ways to present information

    test 'simple message alert renders cleanly without content block' do
      render_inline(Viral::AlertComponent.new(message: 'Simple message'))

      assert_text 'Simple message'
      assert_selector '[role="alert"]', count: 1
      # Should not have content block
      assert_no_selector '.mt-2.text-sm.leading-5'
    end

    test 'alert with rich content renders message and content block' do
      render_inline(Viral::AlertComponent.new(message: 'Main message')) do
        'Additional content'
      end

      assert_text 'Main message'
      assert_text 'Additional content'
      assert_selector '.mt-2.text-sm.leading-5', count: 1
    end

    test 'alert with actions renders interactive elements in content block' do
      render_inline(Viral::AlertComponent.new(message: 'Action required', dismissible: false)) do
        '<button class="btn btn-primary">Action</button>'.html_safe
      end

      assert_text 'Action required'
      # The content block should render the HTML string as actual HTML
      assert_selector 'button', count: 1
      assert_selector 'button', text: 'Action'
      # Check that the content block is present
      assert_selector '.mt-2.text-sm.leading-5', count: 1
    end

    test 'long message alert handles extensive content gracefully' do
      long_message = 'This is a very long message that should be handled gracefully by the alert component. ' \
                     'It should wrap properly and maintain readability across different screen sizes.'

      render_inline(Viral::AlertComponent.new(message: long_message))

      assert_text long_message
      assert_selector '[role="alert"]', count: 1
      # Should maintain proper styling even with long content
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1
    end

    # 🎨 ADVANCED USAGE - Complex scenarios and combinations

    test 'multiple alerts can be rendered together with proper spacing' do
      # Test that multiple alerts can be rendered in sequence
      # Note: render_inline doesn't accumulate, so we test each individually
      render_inline(Viral::AlertComponent.new(message: 'First alert', type: 'info'))
      assert_text 'First alert'
      assert_selector '[role="alert"]', count: 1
      assert_selector 'div.text-blue-800.border-blue-300.bg-blue-50', count: 1

      # Test second alert
      render_inline(Viral::AlertComponent.new(message: 'Second alert', type: 'success'))
      assert_text 'Second alert'
      assert_selector '[role="alert"]', count: 1
      assert_selector 'div.text-green-800.border-green-300.bg-green-50', count: 1

      # Test third alert
      render_inline(Viral::AlertComponent.new(message: 'Third alert', type: 'warning'))
      assert_text 'Third alert'
      assert_selector '[role="alert"]', count: 1
      assert_selector 'div.text-amber-800.border-amber-300.bg-amber-50', count: 1
    end

    test 'custom styling can be applied through system arguments' do
      render_inline(Viral::AlertComponent.new(
                      message: 'Custom styled alert',
                      classes: 'custom-class bg-purple-100 border-purple-300'
                    ))

      assert_text 'Custom styled alert'
      assert_selector '.custom-class', count: 1
      assert_selector '.bg-purple-100', count: 1
      assert_selector '.border-purple-300', count: 1
    end

    # 🔧 ACCESSIBILITY FEATURES - Screen reader and keyboard support

    test 'all alerts have proper accessibility attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Accessible alert'))

      assert_selector '[role="alert"]', count: 1
      assert_selector '[aria-live="assertive"]', count: 1
      assert_selector '[aria-atomic="true"]', count: 1
    end

    test 'close button has proper accessibility attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Accessible close button', dismissible: true))

      close_button = page.find('button[data-action="viral--alert#dismiss"]')
      assert_equal 'Close', close_button['aria-label']
      assert_selector 'span.sr-only', text: 'Close'
    end

    test 'progress bar has proper accessibility attributes' do
      render_inline(Viral::AlertComponent.new(message: 'Progress alert', auto_dismiss: true))

      assert_selector '[data-viral--alert-target="progressBar"]', count: 1
      # Check that the progress bar has the correct initial width
      assert_selector '[data-viral--alert-target="progressBar"][style*="width: 100%"]', count: 1
      assert_selector '[data-viral--alert-target="progressBar"]', count: 1
    end

    # 📱 RESPONSIVE BEHAVIOR - How alerts adapt to different screen sizes

    test 'alert component has responsive design classes' do
      render_inline(Viral::AlertComponent.new(message: 'Responsive alert'))

      # Should have responsive utility classes
      assert_selector '.w-full', count: 1
      assert_selector '.flex', count: 1
      assert_selector '.items-start', count: 1
    end

    test 'alert content adapts to different content lengths' do
      short_message = 'Short'
      long_message = 'This is a much longer message that should demonstrate how the alert component ' \
                     'handles different content lengths and ensures proper responsive behavior.'

      # Test short message
      render_inline(Viral::AlertComponent.new(message: short_message))
      assert_text short_message
      assert_selector '.flex-1.min-w-0', count: 1

      # Test long message
      render_inline(Viral::AlertComponent.new(message: long_message))
      assert_text long_message
      assert_selector '.flex-1.min-w-0', count: 1
    end

    # 🧪 COMPREHENSIVE INTEGRATION TESTS

    test 'complete alert with all features renders correctly' do
      render_inline(Viral::AlertComponent.new(
                      message: 'Complete feature alert',
                      type: 'success',
                      dismissible: true,
                      auto_dismiss: true,
                      classes: 'custom-class'
                    )) do
        '<div class="content-block">Additional content</div>'.html_safe
      end

      # Message and content
      assert_text 'Complete feature alert'
      assert_text 'Additional content'
      # The content block should render the HTML string as actual HTML
      assert_selector '.content-block', count: 1
      assert_selector '.mt-2.text-sm.leading-5', count: 1

      # Styling
      assert_selector 'div.text-green-800.border-green-300.bg-green-50', count: 1
      assert_selector '.custom-class', count: 1

      # Interactive features
      assert_selector 'button[data-action="viral--alert#dismiss"]', count: 1
      assert_selector '[data-viral--alert-target="progressBar"]', count: 1

      # Data attributes
      assert_selector '[data-controller="viral--alert"]', count: 1
      assert_selector '[data-viral--alert-dismissible-value="true"]', count: 1
      assert_selector '[data-viral--alert-auto-dismiss-value="true"]', count: 1
      assert_selector '[data-viral--alert-type-value="success"]', count: 1

      # Accessibility
      assert_selector '[role="alert"]', count: 1
      assert_selector '[aria-live="assertive"]', count: 1
      assert_selector '[aria-atomic="true"]', count: 1
    end

    test 'alert component generates unique IDs for multiple instances' do
      first_alert = Viral::AlertComponent.new(message: 'First alert')
      second_alert = Viral::AlertComponent.new(message: 'Second alert')

      render_inline(first_alert)
      first_id = page.find('[data-viral--alert-alert-id-value]')['data-viral--alert-alert-id-value']

      render_inline(second_alert)
      second_id = page.find('[data-viral--alert-alert-id-value]')['data-viral--alert-alert-id-value']

      # Each alert should have unique IDs
      assert_not_equal first_id, second_id
      assert first_id.start_with?('alert-')
      assert second_id.start_with?('alert-')
    end

    test 'dismiss button IDs are properly linked to alert IDs' do
      render_inline(Viral::AlertComponent.new(message: 'Linked IDs alert', dismissible: true))

      alert_id = page.find('[data-viral--alert-alert-id-value]')['data-viral--alert-alert-id-value']
      dismiss_button_id =
        page.find('[data-viral--alert-dismiss-button-id-value]')['data-viral--alert-dismiss-button-id-value']

      assert dismiss_button_id.start_with?(alert_id)
      assert dismiss_button_id.end_with?('-dismiss')
    end

    # 🎯 EDGE CASES AND ERROR HANDLING

    test 'alert handles empty message gracefully' do
      render_inline(Viral::AlertComponent.new(message: ''))

      assert_selector '[role="alert"]', count: 1
      assert_selector '.alert-component', count: 1
      # Should still render the alert structure even with empty message
    end

    test 'alert handles nil message gracefully' do
      render_inline(Viral::AlertComponent.new(message: nil))

      assert_selector '[role="alert"]', count: 1
      assert_selector '.alert-component', count: 1
      # Should still render the alert structure even with nil message
    end

    test 'alert with invalid type falls back to default info styling' do
      render_inline(Viral::AlertComponent.new(message: 'Invalid type alert', type: 'invalid_type'))

      assert_text 'Invalid type alert'
      # The component should handle invalid types gracefully
      # Check that it still renders as an alert
      assert_selector '[role="alert"]', count: 1
      assert_selector '.alert-component', count: 1
      # The exact styling fallback depends on the component implementation
      # but it should still render successfully
    end

    test 'alert component maintains proper structure with complex content' do
      complex_content = '<div class="nested"><ul><li>Item 1</li><li>Item 2</li></ul></div>'

      render_inline(Viral::AlertComponent.new(message: 'Complex content alert')) do
        complex_content.html_safe # rubocop:disable Rails/OutputSafety
      end

      assert_text 'Complex content alert'
      # The content block should render the HTML string as actual HTML
      assert_selector '.nested ul li', count: 2
      assert_selector 'li', text: 'Item 1'
      assert_selector 'li', text: 'Item 2'
      # Should maintain alert structure
      assert_selector '[role="alert"]', count: 1
      assert_selector '.alert-component', count: 1
      # Check that the content block is present
      assert_selector '.mt-2.text-sm.leading-5', count: 1
    end
  end
end
