# frozen_string_literal: true

module Viral
  # Dropdown component
  class DropdownComponent < Viral::Component
    renders_many :items, Dropdown::ItemComponent
    attr_reader :distance, :dropdown_styles, :label, :icon_name, :caret, :skidding, :trigger, :tooltip

    TRIGGER_DEFAULT = :click
    TRIGGER_MAPPINGS = {
      click: 'click',
      hover: 'hover'
    }.freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(label: nil, tooltip: '', icon: nil, caret: false, trigger: TRIGGER_DEFAULT, skidding: 0,
                   distance: 10, dropdown_styles: '', action_link: false, action_link_value: nil, **system_arguments)
      @distance = distance
      @dropdown_styles = dropdown_styles
      @label = label
      @icon_name = icon
      @caret = caret
      @skidding = skidding
      @action_link = action_link
      @action_link_value = action_link_value
      @trigger = TRIGGER_MAPPINGS[trigger]

      @system_arguments = default_system_arguments(system_arguments)
      @system_arguments[:title] = tooltip if tooltip.present?

      @system_arguments.merge!(system_arguments_for_button) if @label.present?
      @system_arguments.merge!(system_arguments_for_icon) if @icon_name.present?
    end
    # rubocop:enable Metrics/ParameterLists

    def default_system_arguments(args)
      data = { 'viral--dropdown-target': 'trigger' }

      if @action_link
        data = data.merge({
                            action: 'turbo:morph-element->action-link#idempotentConnect',
                            turbo_stream: true,
                            controller: 'action-link',
                            action_link_required_value: @action_link_value
                          })
      end
      args.merge({
                   id: "dd-#{SecureRandom.hex(10)}",
                   data: data,
                   tag: :button,
                   type: :button
                 })
    end

    def system_arguments_for_button
      {
        classes: class_names(
          system_arguments[:classes],
          'flex items-center py-2.5 px-5 text-sm font-medium text-slate-900 ' \
          'focus:outline-none bg-white rounded-md border border-slate-200 ' \
          'hover:bg-slate-100 hover:text-primary-700 focus:z-10 focus:ring-4 ' \
          'focus:ring-primary-200 dark:focus:ring-primary-700 dark:bg-slate-800 ' \
          'dark:text-slate-400 dark:border-slate-600 dark:hover:text-white ' \
          'dark:hover:bg-slate-700'
        )
      }
    end

    def system_arguments_for_icon
      {
        classes: class_names(
          'Viral-Dropdown--icon',
          system_arguments[:classes]
        )
      }
    end
  end
end
