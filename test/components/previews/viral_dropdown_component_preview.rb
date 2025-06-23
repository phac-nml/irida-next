# frozen_string_literal: true

class ViralDropdownComponentPreview < ViewComponent::Preview
  def default
    render Viral::DropdownComponent.new(label: 'Organism', aria: { label: 'Organism dropdown list' },
                                        title: 'Organisms that really shine') do |dropdown|
      dropdown.with_item(label: 'Aspergillus awamori', url: '#')
      dropdown.with_item(label: 'Bacillus cereus', url: '#')
      dropdown.with_item(label: 'Pseudomonas aeruginosa', url: '#')
    end
  end

  def with_caret
    render Viral::DropdownComponent.new(label: 'Organism', aria: { label: 'Organism dropdown list' },
                                        caret: true) do |dropdown|
      dropdown.with_item(label: 'Aspergillus awamori', url: '#')
      dropdown.with_item(label: 'Bacillus cereus', url: '#')
      dropdown.with_item(label: 'Pseudomonas aeruginosa', url: '#')
    end
  end

  def with_icon
    render Viral::DropdownComponent.new(icon: 'bars_3', aria: { label: 'Organism dropdown list' }) do |dropdown|
      dropdown.with_item(label: 'Aspergillus awamori', url: '#')
      dropdown.with_item(label: 'Bacillus cereus', url: '#')
      dropdown.with_item(label: 'Pseudomonas aeruginosa', url: '#')
    end
  end

  def with_item_icon
    render Viral::DropdownComponent.new(icon: 'bars_3', aria: { label: 'Organism Dropdown Menu' }) do |dropdown|
      dropdown.with_item(label: 'Checkmark', url: '#', icon_name: 'check')
      dropdown.with_item(label: 'Inbox', url: '#', icon_name: 'inbox_stack')
    end
  end

  # Preview for custom button_styles
  def with_custom_button_styles
    render(Viral::DropdownComponent.new(
             label: 'Custom Button',
             styles: { button: 'bg-emerald-800 text-white px-4 py-2 flex gap-2 rounded-full cursor-pointer' },
             caret: true
           )) do |dropdown|
      dropdown.with_item(label: 'Item 1', url: '#')
      dropdown.with_item(label: 'Item 2', url: '#')
      dropdown.with_item(label: 'Item 3', url: '#')
    end
  end

  # Preview for dropdown with tooltip
  def with_tooltip
    render(Viral::DropdownComponent.new(
             label: 'Tooltip Button',
             tooltip: 'This is a tooltip!',
             caret: true
           )) do |dropdown|
      dropdown.with_item(label: 'Action 1', url: '#')
    end
  end

  def with_icon_and_tooltip
    render Viral::DropdownComponent.new(
      icon: 'bars_3',
      tooltip: 'This is a tooltip!',
      aria: { label: 'Organism dropdown list' }
    ) do |dropdown|
      dropdown.with_item(label: 'Action 1', url: '#')
    end
  end

  # Preview for dropdown items with data attributes
  def with_data_attributes
    render Viral::DropdownComponent.new(
      label: 'Data Attributes Test',
      caret: true
    ) do |dropdown|
      dropdown_items.each { |item| dropdown.with_item(**item) }
    end
  end

  private

  def dropdown_items # rubocop:disable Metrics/MethodLength
    [
      {
        label: 'Item with Data',
        url: '#',
        data: {
          action: 'click->test#action',
          test_id: 'dropdown-item-1',
          confirm: 'Are you sure?'
        }
      },
      {
        label: 'Another Item',
        url: '#',
        data: {
          test_id: 'dropdown-item-2',
          turbo_method: 'delete'
        },
        class: 'text-red-600'
      }
    ]
  end
end
