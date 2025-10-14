# frozen_string_literal: true

# Component for rendering a drop down that filters dynamically
class SelectWithAutoCompleteComponent < Component
  def initialize(label:, combobox_id:, listbox_id:)
    @label = label
    @combobox_id = combobox_id
    @listbox_id = listbox_id
  end
end
