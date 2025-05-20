# frozen_string_literal: true

class ViralDropdownComponentPreview < ViewComponent::Preview
  def default; end

  def with_caret; end

  def with_icon; end

  def with_item_icon; end

  # Preview for custom button_styles
  def with_custom_button_styles
    render(Viral::DropdownComponent.new(
             label: 'Custom',
             button_styles: 'bg-emerald-800 text-white px-4 py-2 flex gap-2 rounded-full cursor-pointer',
             caret: true
           )) do |dropdown|
      dropdown.with_item(label: 'Item 1', url: '#')
      dropdown.with_item(label: 'Item 2', url: '#')
      dropdown.with_item(label: 'Item 3', url: '#')
    end
  end
end
