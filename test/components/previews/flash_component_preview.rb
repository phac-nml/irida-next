# frozen_string_literal: true

class FlashComponentPreview < ViewComponent::Preview
  def success
    render Viral::FlashComponent.new(type: 'success', data: 'Successful Message!', timeout: 0)
  end

  def error
    render Viral::FlashComponent.new(type: 'error', data: 'Error Message!', timeout: 0)
  end

  def warning
    render Viral::FlashComponent.new(type: 'warning', data: 'Warning Message!', timeout: 0)
  end

  def info
    render Viral::FlashComponent.new(type: 'info', data: 'Info Message!', timeout: 0)
  end
end
