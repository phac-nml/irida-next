# frozen_string_literal: true

require 'test_helper'

class FlashComponentTest < ViewComponent::TestCase
  test 'test success message' do
    message = 'Successful Message!'
    render_inline(FlashComponent.new(type: 'success', data: message))
    assert_text message
    assert_selector '.bg-green-700'
  end

  test 'test error message' do
    message = 'Error Message!'
    render_inline(FlashComponent.new(type: 'error', data: message))
    assert_text message
    assert_selector '.bg-red-600'
  end

  test 'test warning message' do
    message = 'Warning Message!'
    render_inline(FlashComponent.new(type: 'warning', data: message))
    assert_text message
    assert_selector '.bg-yellow-600'
  end

  test 'test info smessage' do
    message = 'Info Message!'
    render_inline(FlashComponent.new(type: 'info', data: message))
    assert_text message
    assert_selector '.bg-blue-600'
  end
end
