# frozen_string_literal: true

class ClipboardComponentPreview < ViewComponent::Preview
  def default
    render(ClipboardComponent.new)
  end
end
