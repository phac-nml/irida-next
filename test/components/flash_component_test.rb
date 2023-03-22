# frozen_string_literal: true

require 'test_helper'

class FlashComponentTest < ViewComponent::TestCase
  def test_success_message
    message = 'Successful Message!'
    render_inline(FlashComponent.new(type: 'success', data: message))
    assert_text message
    assert_selector '.bg-green-700'
  end

  def test_error_message
    message = 'Error Message!'
    render_inline(FlashComponent.new(type: 'error', data: message))
    assert_text message
    assert_selector '.bg-red-600'
  end

  def test_warning_message
    message = 'Warning Message!'
    render_inline(FlashComponent.new(type: 'warning', data: message))
    assert_text message
    assert_selector '.bg-yellow-600'
  end

  def test_info_message
    message = 'Info Message!'
    render_inline(FlashComponent.new(type: 'info', data: message))
    assert_text message
    assert_selector '.bg-blue-600'
  end
end
