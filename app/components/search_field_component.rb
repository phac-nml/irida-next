# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  def initialize(label:, placeholder:, form:, field_name:, value: nil)
    @label = label
    @placeholder = placeholder
    @form = form
    @field_name = field_name
    @value = value
  end

  def clear_button?
    @value.present?
  end
end
