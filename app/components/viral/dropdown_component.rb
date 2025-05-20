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
    def initialize(label: nil, tooltip: '', icon: nil, caret: false, trigger: TRIGGER_DEFAULT, skidding: 0,
                   distance: 10, styles: {}, action_link: false, action_link_value: nil, **system_arguments)
      @distance = distance
      @styles = styles.with_indifferent_access
      @label = label
      @icon_name = icon
      @caret = caret
      @skidding = skidding
      @action_link = action_link
      @action_link_value = action_link_value
      @trigger = TRIGGER_MAPPINGS.fetch(trigger, TRIGGER_MAPPINGS[TRIGGER_DEFAULT])
      @dd_id = "dd-#{SecureRandom.hex(10)}"

      @system_arguments = build_system_arguments(system_arguments)
      @system_arguments[:title] = tooltip if tooltip.present?
      # Ensure custom button styles fully override any default classes
      if label.present?
        if styles[:button].present?
          @system_arguments[:classes] = styles[:button]
        else
          @system_arguments.merge!(system_arguments_for_button)
        end
      end
      @system_arguments.merge!(system_arguments_for_icon) if icon_name.present?
    end

    private

    # Build the base system arguments for the dropdown trigger button.
    def build_system_arguments(args)
      data = { 'viral--dropdown-target': 'trigger' }
      if @action_link
        data.merge!({
                      action: 'turbo:morph-element->action-button#idempotentConnect',
                      turbo_stream: true,
                      controller: 'action-button',
                      action_link_required_value: @action_link_value
                    })
      end
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

    # Returns system arguments for the dropdown button, using custom styles if provided.
    def system_arguments_for_button
      if styles[:button].present?
        { classes: styles[:button] }
      else
        {
          classes: class_names(
            'text-slate-600 dark:text-slate-400 border border-slate-300 min-h-11 min-w-11 dark:border-slate-600 rounded-lg text-sm px-3 py-1 cursor-pointer inline-flex items-center justify-center',
            system_arguments[:classes]
          )
        }
      end
    end

    # Returns system arguments for the icon, merging with any existing classes.
    def system_arguments_for_icon
      {
        classes: class_names('viral-dropdown--icon', system_arguments[:classes])
      }
    end
  end
end
