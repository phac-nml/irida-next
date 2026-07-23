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
    compact: false,
    **system_arguments
  )
    # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength
    @label = label
    @placeholder = placeholder
    @form = form
    @field_name = field_name
    @value = value
    @toolbar_item = toolbar_item
    @compact = compact
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      'flex flex-col'
    )
    @system_arguments[:data] ||= {}
    @system_arguments[:data][:action] = 'focusin->search-field#onFocusin focusout->search-field#onFocusout'
    @system_arguments[:data][:controller] = 'search-field'
    @system_arguments[:data][:'search-field-toolbar-item-value'] = true if @toolbar_item
    return unless include_advanced_search_outlet

    @system_arguments[:data][:'search-field-advanced-search--v1-outlet'] =
      '#advanced-search'
  end

  def clear_button?
    @value.present?
  end

  def compact?
    @compact
  end

  def field_shell_classes
    compact? ? 'relative h-8' : 'relative h-[44px]'
  end

  def field_input_classes
    class_names(
      't-search-component h-full w-full placeholder-shown:field-sizing-content block border',
      'border-slate-300 rounded-lg bg-slate-50 text-slate-900 dark:border-slate-600',
      'dark:bg-slate-700 dark:placeholder-slate-300 dark:text-white',
      compact? ? 'px-2 py-1 pr-8 text-xs' : 'p-2.5 pr-11.5 text-sm'
    )
  end

  def field_action_classes
    class_names(
      'pointer-events-auto absolute inset-y-0 right-0 flex cursor-pointer items-center justify-center',
      'rounded-r-lg border-t border-r border-b border-slate-300 transition-colors',
      'hover:bg-slate-100 dark:border-slate-600 dark:hover:bg-slate-600',
      compact? ? 'w-8' : 'w-[44px]'
    )
  end
end
