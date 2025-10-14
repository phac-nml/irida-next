# frozen_string_literal: true

class SelectWithAutoCompleteComponentPreview < ViewComponent::Preview
  def default
    render_with_template(locals: {
                           label: 'Cities',
                           combobox_id: 'combobox_id',
                           listbox_id: 'listbox_id'
                         })
  end
end
