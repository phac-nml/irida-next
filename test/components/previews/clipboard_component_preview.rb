# frozen_string_literal: true

class ClipboardComponentPreview < ViewComponent::Preview
  def default
    render ClipboardComponent.new(value: 'Text to copy', aria_label: 'Secret text to copy to clipboard')
  end
end
