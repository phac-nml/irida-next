# frozen_string_literal: true

module Pathogen
  # The `ButtonVisuals` module provides functionality for rendering leading and trailing
  # visual elements (like icons or SVGs) within components, typically buttons.
  # It leverages ViewComponent's `renders_one` to define slots for these visuals
  # and provides helper methods to construct `Pathogen::Icon` or generic SVG components.
  #
  # SVG visuals can be created either by passing attributes or using a block to define
  # the SVG content more explicitly.
  #
  # This module is intended to be included in components that need to display
  # such visual adornments.
  #
  # @example Using icon visual
  #   <%= render Pathogen::Button.new do |c| %>
  #     <% c.with_leading_visual_icon(icon: :check) %>
  #     Submit
  #   <% end %>
  #
  # @example Using SVG visual with attributes
  #   <%= render Pathogen::Button.new do |c| %>
  #     <% c.with_leading_visual_svg(viewBox: "0 0 16 16", path: "M8 0a8 8 0 100 16A8 8 0 008 0zm3.5 9L8 5.5 4.5 9 3 7.5 8 2.5l5 5L11.5 9z") %>
  #     Success
  #   <% end %>
  #
  # @example Using SVG visual with block
  #   <%= render Pathogen::Button.new do |c| %>
  #     <% c.with_leading_visual_svg(viewBox: "0 0 16 16") do %>
  #       <path d="M8 0a8 8 0 100 16A8 8 0 008 0zm3.5 9L8 5.5 4.5 9 3 7.5 8 2.5l5 5L11.5 9z" />
  #     <% end %>
  #     Submit
  #   <% end %>
  module ButtonVisuals
    # Default CSS classes applied to icons rendered by this module.
    DEFAULT_ICON_CLASSES = 'w-4 h-4'

    # @!parse
    #   # Defines a slot for a leading visual element.
    #   # @!method leading_visual(type: :icon, **options, &block)
    #   #   @param type [Symbol] The type of visual to render (:icon or :svg).
    #   #   @param options [Hash] Options passed to the visual component.
    #   #   @param block [Proc] Optional block for SVG content when type is :svg.
    #   #   @return [void]
    #   renders_one :leading_visual
    #
    #   # Defines a slot for a trailing visual element.
    #   # @!method trailing_visual(type: :icon, **options, &block)
    #   #   @param type [Symbol] The type of visual to render (:icon or :svg).
    #   #   @param options [Hash] Options passed to the visual component.
    #   #   @param block [Proc] Optional block for SVG content when type is :svg.
    #   #   @return [void]
    #   renders_one :trailing_visual
    #
    # @!visibility private
    def self.included(base)
      base.renders_one :leading_visual, types: visual_types(name: :leading_visual)
      base.renders_one :trailing_visual, types: visual_types(name: :trailing_visual)
    end

    # Defines the types of visual elements that can be rendered (e.g., :icon, :svg).
    # This method is used by `renders_one` to specify the allowed visual types and
    # the lambdas responsible for creating them.
    #
    # @param name [Symbol] The name of the visual slot (e.g., :leading_visual, :trailing_visual).
    #   This is used to generate unique CSS classes for the visual elements.
    # @return [Hash{Symbol => Proc}] A hash where keys are visual type names (e.g., :icon)
    #   and values are lambdas that construct the corresponding visual component.
    def self.visual_types(name:)
      {
        icon: ->(**args) { icon_visual(args, name) },
        svg: ->(**args, &block) { svg_visual(args, name, block) }
      }
    end
    private_class_method :visual_types # Make visual_types private as it's an internal helper for `included`

    # Constructs a `Pathogen::Icon` component.
    # This method is typically called by the lambda defined in `visual_types`.
    #
    # @param args [Hash] Arguments to be passed to the `Pathogen::Icon` initializer.
    #   This includes `:icon` (the icon name), and any other options like `:variant`, `:class`.
    # @param name [Symbol] The name of the visual slot (e.g., :leading_visual).
    #   Used to add a specific CSS class (e.g., "leading_visual_icon").
    # @return [Pathogen::Icon] An instance of `Pathogen::Icon`.
    def icon_visual(args, name)
      # Prepend default icon classes and a slot-specific class.
      args[:class] = class_names(icon_classes, args[:class], "#{name}_icon")
      Pathogen::Icon.new(**args)
    end

    # Constructs a `Pathogen::BaseComponent` configured to render an SVG.
    # This method is typically called by the lambda defined in `visual_types`.
    #
    # @param args [Hash] Arguments to be passed to the `Pathogen::BaseComponent` initializer.
    #   This can include attributes like `:viewBox`, etc.
    #   Default width and height are set to '16'.
    # @param name [Symbol] The name of the visual slot (e.g., :leading_visual).
    #   Used to add a specific CSS class (e.g., "leading_visual_svg").
    # @param block [Proc, nil] An optional block for SVG content. When provided, the SVG is built with the content
    #   from the block rather than using attributes like :path from args.
    # @return [Pathogen::BaseComponent] An instance of `Pathogen::BaseComponent` configured as an SVG.
    def svg_visual(args, name, block = nil)
      # Ensure `classes` is used for Pathogen::BaseComponent if that's its expected param name,
      # or adjust if it expects :class. Assuming :classes from the original code.
      # Add a slot-specific class and 'fill-current'.
      existing_classes = args.delete(:classes) || args.delete(:class)
      combined_classes = class_names("#{name}_svg", 'fill-current', existing_classes)

      # Default attributes for the SVG
      svg_attributes = {
        tag: :svg,
        width: args.delete(:width) || '16', # Default width
        height: args.delete(:height) || '16', # Default height
        class: combined_classes, # Use :class as it's more standard for ViewComponent/HTML attributes
        **args # Pass remaining args like viewBox, etc.
      }

      if block
        # When a block is provided, use it as content
        Pathogen::BaseComponent.new(**svg_attributes, &block)
      else
        # Otherwise use the standard approach with attributes only
        Pathogen::BaseComponent.new(**svg_attributes)
      end
    end

    private

    # Returns the default CSS classes for icons.
    #
    # @return [String] The default CSS classes.
    def icon_classes
      DEFAULT_ICON_CLASSES
    end
  end
end
