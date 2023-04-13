# frozen_string_literal: true

class DropdownComponentPreview < ViewComponent::Preview
  def default
    render Viral::DropdownComponent.new do |dropdown|
      dropdown.trigger { 'Dropdown' }
      dropdown.item(label: 'Item 1', url: '#')
      dropdown.item(label: 'Item 2', url: '#')
    end
  end
end
