# frozen_string_literal: true

class DropdownComponentPreview < ViewComponent::Preview
  def default
    render Viral::DropdownComponent.new
  end
end
