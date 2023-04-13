# frozen_string_literal: true

class DropdownComponentPreview < ViewComponent::Preview
  def default
    render Viral::DropdownComponent.new(label: 'Items', caret: true) do |dropdown|
      dropdown.item(label: 'Item 1', url: '#')
      dropdown.item(label: 'Item 2', url: '#')
    end
  end

  def with_icon
    render Viral::DropdownComponent.new(icon: 'bars_3') do |dropdown|
      dropdown.item(label: 'Item 1', url: '#')
      dropdown.item(label: 'Item 2', url: '#')
    end
  end
end
