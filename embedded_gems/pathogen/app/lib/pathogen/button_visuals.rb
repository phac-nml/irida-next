# frozen_string_literal: true

module Pathogen
  # 🎨 ButtonVisuals Module
  #
  # Provides visual enhancements for buttons in the Pathogen component library.
  # Handles the rendering and styling of icons and SVGs in leading and trailing
  # positions within buttons.
  #
  # Features:
  # - 🖼️ Support for icons and SVGs
  # - ⬅️ Leading visual elements
  # - ➡️ Trailing visual elements
  # - 📏 Automatic size scaling
  # - 🎯 Consistent positioning
  #
  # @example Using with icons
  #   = render(Button.new) do |b|
  #     b.with_leading_visual(icon: "check")
  #     = "Confirm"
  #
  # @example Using with SVGs
  #   = render(Button.new) do |b|
  #     b.with_trailing_visual(svg: { path: "M1 1..." })
  #     = "Next"
  module ButtonVisuals
    # 📏 Predefined icon size mappings for consistent scaling
    ICON_SIZE_MAPPINGS = {
      sm: 'w-4 h-4', # 12x12 pixels
      base: 'w-4 h-4', # 16x16 pixels
      lg: 'w-6 h-6' # 20x20 pixels
    }.freeze

    # 🔌 Module inclusion hook
    #
    # Sets up the component to render leading and trailing visuals
    # using the defined visual types (icons and SVGs).
    #
    # @param base [Class] The including class
    def self.included(base)
      base.renders_one :leading_visual, types: visual_types
      base.renders_one :trailing_visual, types: visual_types
    end

    # 🎨 Defines available visual element types
    #
    # @return [Hash] Mapping of visual types to their rendering functions
    def self.visual_types
      {
        icon: ->(**args) { icon_visual(args) },
        svg: ->(**args) { svg_visual(args) }
      }
    end

    # 🖼️ Creates an icon visual component
    #
    # @param args [Hash] Icon component arguments
    # @return [Pathogen::Icon] Configured icon component
    def icon_visual(args)
      args[:class] = class_names(
        args[:class],
        ICON_SIZE_MAPPINGS[@size]
      )
      Pathogen::Icon.new(**args)
    end

    # ⚡ Creates an SVG visual component
    #
    # @param args [Hash] SVG component arguments
    # @return [Pathogen::BaseComponent] Configured SVG component
    def svg_visual(args)
      Pathogen::BaseComponent.new(
        tag: :svg,
        width: '16',
        height: '16',
        classes: 'fill-current',
        **args
      )
    end
  end
end
