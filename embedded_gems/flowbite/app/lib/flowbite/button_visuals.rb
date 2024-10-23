# frozen_string_literal: true

module Flowbite
  # Provides visual components (icons) and helpers for button styling in Flowbite
  module ButtonVisuals
    # A hash of predefined icon size mappings
    ICON_SIZE_MAPPINGS = {
      small: 'w-3 h-3',
      medium: 'w-3 h-3'
    }.freeze

    def self.included(base)
      base.renders_one :leading_visual, types: visual_types(:me)
      base.renders_one :trailing_visual, types: visual_types(:ms)
    end

    def self.visual_types(margin_direction)
      {
        icon: ->(**args) { icon_visual(args, margin_direction) },
        svg: ->(**args) { svg_visual(args, margin_direction) }
      }
    end

    def icon_visual(args, margin_direction)
      args[:class] = class_names(args[:class], icon_classes(margin_direction))
      Flowbite::Icon.new(**args)
    end

    def svg_visual(args, margin_direction)
      Flowbite::BaseComponent.new(
        tag: :span,
        classes: class_names(icon_classes(margin_direction)),
        **args
      )
    end

    private

    def icon_classes(margin_direction)
      [
        ICON_SIZE_MAPPINGS[fetch_or_fallback(Flowbite::ButtonSizes::SIZE_OPTIONS, @size,
                                             Flowbite::ButtonSizes::DEFAULT_SIZE)],
        "#{margin_direction}-2",
        ('min-w-4' if margin_direction == :ms)
      ].compact
    end
  end
end
