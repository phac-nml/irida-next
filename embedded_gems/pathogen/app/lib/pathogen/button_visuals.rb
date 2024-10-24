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
      base.renders_one :leading_visual, types: visual_types(margin_direction: :mr, name: :leading_visual)
      base.renders_one :trailing_visual, types: visual_types(margin_direction: :ml, name: :trailing_visual)
    end

    def self.visual_types(margin_direction:, name:)
      {
        icon: ->(**args) { icon_visual(args, margin_direction, name) },
        svg: ->(**args) { svg_visual(args, margin_direction, name) }
      }
    end

    def icon_visual(args, margin_direction, name)
      args[:class] = class_names(args[:class], icon_classes(margin_direction), "#{name}_icon")
      Pathogen::Icon.new(**args)
    end

    def svg_visual(args, margin_direction, name)
      Pathogen::BaseComponent.new(
        tag: :span,
        classes: class_names(icon_classes(margin_direction), "#{name}_svg"),
        **args
      )
    end

    private

    def icon_classes(margin_direction)
      [
        ICON_SIZE_MAPPINGS[fetch_or_fallback(Pathogen::ButtonSizes::SIZE_OPTIONS, @size,
                                             Pathogen::ButtonSizes::DEFAULT_SIZE)],
        "#{margin_direction}-#{@size == :small ? 1 : 2}"
      ].compact
    end
  end
end
