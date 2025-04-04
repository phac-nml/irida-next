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
      small: 'w-3 h-3',   # 12x12 pixels
      medium: 'w-4 h-4'   # 16x16 pixels
    }.freeze

    # 🔌 Module inclusion hook
    #
    # Sets up the component to render leading and trailing visuals
    # using the defined visual types (icons and SVGs).
    #
    # @param base [Class] The including class
    def self.included(base)
      base.renders_one :leading_visual, types: visual_types(name: :leading_visual)
      base.renders_one :trailing_visual, types: visual_types(name: :trailing_visual)
    end

    # 🎨 Defines available visual element types
    #
    # @param name [Symbol] The name of the visual slot (:leading_visual or :trailing_visual)
    # @return [Hash] Mapping of visual types to their rendering functions
    def self.visual_types(name:)
      {
        icon: ->(**args) { icon_visual(args, name) },
        svg: ->(**args) { svg_visual(args, name) }
      }
    end

    # 🖼️ Creates an icon visual component
    #
    # @param args [Hash] Icon component arguments
    # @param name [Symbol] The name of the visual slot
    # @return [Pathogen::Icon] Configured icon component
    def icon_visual(args, name)
      args[:class] = class_names(
        args[:class],
        icon_classes,
        "#{name}_icon"
      )
      Pathogen::Icon.new(**args)
    end

    # ⚡ Creates an SVG visual component
    #
    # @param args [Hash] SVG component arguments
    # @param name [Symbol] The name of the visual slot
    # @return [Pathogen::BaseComponent] Configured SVG component
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

    # 📐 Generates size-specific classes for icons
    #
    # @return [Array<String>] Array of Tailwind CSS classes for icon sizing
    def icon_classes
      [
        Pathogen::ButtonStyles::ICON_SIZES[@size]
      ].compact
    end
  end
end
