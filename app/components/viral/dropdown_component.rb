# frozen_string_literal: true

module Viral
  # Professional, idiomatic dropdown component for Viral UI
  class DropdownComponent < Viral::Component
    renders_many :items, Dropdown::ItemComponent

    # Public: Expose key dropdown configuration
    attr_reader :distance, :label, :icon_name, :caret, :skidding, :trigger, :tooltip, :styles

    TRIGGER_DEFAULT = :click
    TRIGGER_MAPPINGS = {
      click: 'click',
      hover: 'hover'
    }.freeze

    # Initialize a new DropdownComponent.
    #
    # label        - Optional String label for the button.
    # tooltip      - Optional String for button tooltip.
    # icon         - Optional String icon name.
    # caret        - Boolean, show dropdown caret icon.
    # trigger      - Symbol, :click or :hover (default :click).
    # skidding     - Integer, popper.js skidding offset.
    # distance     - Integer, popper.js distance offset.
    # dropdown_styles - String, custom styles for dropdown menu.
    # button_styles   - String, custom Tailwind classes for button (overrides default).
    # action_link     - Boolean, use as action button.
    # action_link_value - Value for action button.
    # system_arguments - Additional HTML/system args.
    def initialize(**params)
      @params = params
      set_basic_attributes
      set_system_arguments
    end

    private

    def set_basic_attributes
      @distance = @params[:distance] || 10
      @styles = (@params[:styles] || {}).with_indifferent_access
      @label = @params[:label]
      @icon_name = @params[:icon]
      @caret = @params[:caret]
      @skidding = @params[:skidding] || 0
      @action_link = @params[:action_link]
      @action_link_value = @params[:action_link_value]
      @trigger = TRIGGER_MAPPINGS.fetch(
        @params[:trigger] || TRIGGER_DEFAULT,
        TRIGGER_MAPPINGS[TRIGGER_DEFAULT]
      )
      @dd_id = "dd-#{SecureRandom.hex(10)}"
    end

    def set_system_arguments
      @system_arguments = build_system_arguments(@params)
      add_tooltip
      add_button_styles
      add_icon_styles
    end

    def add_tooltip
      return if @params[:tooltip].blank?

      @system_arguments[:title] = @params[:tooltip]
    end

    def add_button_styles
      return if @label.blank?

      if @styles[:button].present?
        @system_arguments[:classes] = @styles[:button]
      else
        @system_arguments.merge!(system_arguments_for_button)
      end
    end

    def add_icon_styles
      return if @icon_name.blank?

      @system_arguments.merge!(system_arguments_for_icon)
    end

    def build_system_arguments(args)
      data = build_data_attributes
      args.merge(
        id: "dd-#{SecureRandom.hex(10)}",
        data: data,
        tag: :button,
        type: :button,
        classes: 'cursor-pointer',
        'aria-expanded': false,
        'aria-haspopup': true,
        'aria-controls': @dd_id
      )
    end

    def build_data_attributes
      data = { 'viral--dropdown-target': 'trigger' }
      return data unless @action_link

      data.merge(
        action: 'turbo:morph-element->action-button#idempotentConnect',
        turbo_stream: true,
        controller: 'action-button',
        action_link_required_value: @action_link_value
      )
    end

    def system_arguments_for_button
      return { classes: @styles[:button] } if @styles[:button].present?

      {
        classes: class_names(
          'text-slate-600 dark:text-slate-400',
          'border border-slate-300 min-h-11 min-w-11',
          'dark:border-slate-600 rounded-lg text-sm',
          'px-3 py-1 cursor-pointer',
          'inline-flex items-center justify-center',
          @system_arguments[:classes]
        )
      }
    end

    def system_arguments_for_icon
      {
        classes: class_names('viral-dropdown--icon', @system_arguments[:classes])
      }
    end
  end
end
