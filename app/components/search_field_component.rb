# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  def initialize(label:, form:, field_name:, value: nil, **system_arguments)
    @label = label
    @form = form
    @field_name = field_name
    @value = value
    @system_arguments = system_arguments

    @system_arguments[:data] ||= {}
    @system_arguments[:data][:action] = 'focusin->search-field#onFocusin focusout->search-field#onFocusout'
    @system_arguments[:data][:controller] = 'search-field'
  end

  def clear_button?
    @value.present?
  end
end
