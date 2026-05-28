# frozen_string_literal: true

# Component for rendering a search field with a submit button
class SearchFieldComponent < Component
  # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
  def initialize(
    label:,
    placeholder:,
    form:,
    field_name:,
    value: nil,
    include_advanced_search_outlet: false,
    toolbar_item: false,
    **system_arguments
  )
    # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength
    @label = label
    @placeholder = placeholder
    @form = form
    @field_name = field_name
    @value = value
    @toolbar_item = toolbar_item
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      'flex flex-col'
    )
    @system_arguments[:data] ||= {}
    @system_arguments[:data][:action] = 'focusin->search-field#onFocusin focusout->search-field#onFocusout'
    @system_arguments[:data][:controller] = 'search-field'
    return unless include_advanced_search_outlet

    @system_arguments[:data][:'search-field-advanced-search-outlet'] =
      '#advanced-search'
    @system_arguments[:data][:'search-field-advanced-search--v1-outlet'] =
      '#advanced-search'
  end

  def clear_button?
    @value.present?
  end
end
