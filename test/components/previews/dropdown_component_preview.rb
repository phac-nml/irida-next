# frozen_string_literal: true

class DropdownComponentPreview < ViewComponent::Preview
  def with_label_and_caret
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

  def with_item_icon
    render Viral::DropdownComponent.new(label: 'Items', caret: true) do |dropdown|
      dropdown.item(label: 'Item 1', url: '#', icon_name: 'check')
      dropdown.item(label: 'Item 2', url: '#', icon_name: 'inbox_stack')
    end
  end
end
