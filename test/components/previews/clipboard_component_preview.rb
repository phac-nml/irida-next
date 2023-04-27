# frozen_string_literal: true

class ClipboardComponentPreview < ViewComponent::Preview
  def default
    render ClipboardComponent.new(value: 'Text to copy')
  end
end
