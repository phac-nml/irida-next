# frozen_string_literal: true

class FlashComponentPreview < ViewComponent::Preview
  def success
    render Viral::FlashComponent.new(type: 'success', data: 'Successful Message!')
  end

  def error
    render Viral::FlashComponent.new(type: 'error', data: 'Error Message!')
  end

  def warning
    render Viral::FlashComponent.new(type: 'warning', data: 'Warning Message!')
  end

  def info
    render Viral::FlashComponent.new(type: 'info', data: 'Info Message!')
  end
end
