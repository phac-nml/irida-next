# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  def initialize(label:, placeholder:, form:, field_name:, value: nil, **system_arguments) # rubocop:disable Metrics/ParameterLists
    @label = label
    @placeholder = placeholder
    @form = form
    @field_name = field_name
    @value = value
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      'flex flex-col'
    )
    @system_arguments[:data] ||= {}
    @system_arguments[:data][:action] = 'focusin->search-field#onFocusin focusout->search-field#onFocusout'
    @system_arguments[:data][:controller] = 'search-field'
  end

  def clear_button?
    @value.present?
  end
end
