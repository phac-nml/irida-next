# frozen_string_literal: true

module Pathogen
  # Provides visual components (icons) and helpers for button styling in Pathogen
  module ButtonVisuals
    # Default icon size class
    DEFAULT_ICON_CLASSES = 'w-4 h-4'.freeze

    def self.included(base)
      base.renders_one :leading_visual, types: visual_types(name: :leading_visual)
      base.renders_one :trailing_visual, types: visual_types(name: :trailing_visual)
    end

    def self.visual_types(name:)
      {
        icon: ->(**args) { icon_visual(args, name) },
        svg: ->(**args) { svg_visual(args, name) }
      }
    end

    def icon_visual(args, name)
      args[:class] = class_names(args[:class], icon_classes, "#{name}_icon")
      Pathogen::Icon.new(**args)
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
      DEFAULT_ICON_CLASSES
    end
  end
end
