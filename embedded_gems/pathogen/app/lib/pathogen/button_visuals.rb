# frozen_string_literal: true

module Pathogen
  # Provides visual components (icons) and helpers for button styling in Pathogen
  module ButtonVisuals
    # A hash of predefined icon size mappings
    ICON_SIZE_MAPPINGS = {
      small: 'w-3 h-3',
      medium: 'w-4 h-4'
    }.freeze

    def self.included(base)
      base.renders_one :leading_visual, types: visual_types(name: :leading_visual)
      base.renders_one :trailing_visual, types: visual_types(name: :trailing_visual)
    end

    def self.visual_types(name:)
      {
        icon: ->(**args) { icon_visual(args) },
        svg: ->(**args) { svg_visual(args, name) }
      }
    end

    def icon_visual(args)
      icon_name = args[:icon]
      args.delete(:icon)
      args[:class] = class_names(args[:class], icon_classes)
      # Ensure icons inherit button text color unless explicitly overridden
      args[:color] = nil unless args.key?(:color)

      # Use the enhanced Pathogen::Icon component for better functionality
      # (includes debug classes, error handling, accessibility defaults)
      Pathogen::Icon.new(icon_name, **args)
    end

    def svg_visual(args, name)
      Pathogen::BaseComponent.new(
        tag: :svg,
        width: '16',
        height: '16',
        classes: "#{name}_svg fill-current",
        **args
      )
    end

    private

    def icon_classes
      [
        ICON_SIZE_MAPPINGS[fetch_or_fallback(Pathogen::ButtonSizes::SIZE_OPTIONS, @size,
                                             Pathogen::ButtonSizes::DEFAULT_SIZE)]
      ].compact
    end
  end
end
