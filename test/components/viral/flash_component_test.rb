# frozen_string_literal: true

require 'view_component_system_test_case'

module Viral
  class FlashComponentTest < ViewComponent::SystemTestCase
    test 'success message' do
      message = 'Successful Message!'
      render_inline(Viral::FlashComponent.new(type: 'success', data: message))
      assert_text message
      assert_selector '.bg-green-700'
      find('[data-action="flash#dismiss"]').click
      assert_no_text message
    end

    test 'error message' do
      message = 'Error Message!'
      render_inline(Viral::FlashComponent.new(type: 'error', data: message))
      assert_text message
      assert_selector '.bg-red-600'
    end

    test 'warning message' do
      message = 'Warning Message!'
      render_inline(Viral::FlashComponent.new(type: 'warning', data: message))
      assert_text message
      assert_selector '.bg-yellow-600'
    end

    test 'info message' do
      message = 'Info Message!'
      render_inline(Viral::FlashComponent.new(type: 'info', data: message))
      assert_text message
      assert_selector '.bg-blue-600'
    end
  end
end
