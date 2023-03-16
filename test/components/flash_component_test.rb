# frozen_string_literal: true

require 'test_helper'

class FlashComponentTest < ViewComponent::TestCase
  def test_success_message
    message = 'Successful Message!'
    render_inline(FlashComponent.new(type: :success)) { message }
    assert_text message
    assert_selector '.bg-green-100 > svg'
  end

  def test_error_message
    message = 'Error Message!'
    render_inline(FlashComponent.new(type: :error)) { message }
    assert_text message
    assert_selector '.bg-red-100 > svg'
  end

  def test_warning_message
    message = 'Warning Message!'
    render_inline(FlashComponent.new(type: :warning)) { message }
    assert_text message
    assert_selector '.bg-yellow-100 > svg'
  end

  def test_info_message
    message = 'Info Message!'
    render_inline(FlashComponent.new(type: :info)) { message }
    assert_text message
    assert_selector '.bg-blue-100 > svg'
  end
end
