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
      @dd_id = "dd-#{SecureRandom.hex(10)}"

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
                            action: 'turbo:morph-element->action-button#idempotentConnect',
                            turbo_stream: true,
                            controller: 'action-button',
                            action_link_required_value: @action_link_value
                          })
      end
      args.merge({
                   id: "dd-#{SecureRandom.hex(10)}",
                   data:,
                   tag: :button,
                   type: :button,
                   classes: 'cursor-pointer',
                   'aria-expanded': false,
                   'aria-haspopup': true,
                   'aria-controls': @dd_id
                 })
    end

    def system_arguments_for_button
      {
        classes: class_names(
          'text-slate-600 dark:text-slate-400 border border-slate-300 min-h-11 min-w-11
      dark:border-slate-600 rounded-lg text-sm px-3 py-1 cursor-pointer inline-flex
      items-center justify-center',
          system_arguments[:classes]
        )
      }
    end

    def system_arguments_for_icon
      {
        classes: class_names(
          'viral-dropdown--icon',
          system_arguments[:classes]
        )
      }
    end
  end
end
