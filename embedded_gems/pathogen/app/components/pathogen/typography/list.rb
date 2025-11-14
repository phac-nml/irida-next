# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering ordered and unordered lists
    #
    # Supports both ordered (ol) and unordered (ul) lists with consistent spacing
    # and styling. Note: Currently accepts items as an array parameter due to
    # ViewComponent slot limitations. Future versions may support slots API.
    #
    # @example Unordered list
    #   <%= render Pathogen::Typography::List.new(items: ["Item 1", "Item 2", "Item 3"]) %>
    #
    # @example Ordered list
    #   <%= render Pathogen::Typography::List.new(ordered: true, items: ["Step 1", "Step 2"]) %>
    #
    # @example With variant
    #   <%= render Pathogen::Typography::List.new(variant: :muted, items: ["Item 1", "Item 2"]) %>
    class List < Component
      include Shared

      DEFAULT_TAG = :ul

      attr_reader :ordered, :variant, :items

      # Initialize a new List component
      #
      # @param ordered [Boolean] Use ordered list (ol) instead of unordered (ul)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param items [Array<String>] Array of list item strings
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(ordered: false, variant: Shared::DEFAULT_VARIANT, items: [], **system_arguments)
        @ordered = ordered
        @variant = variant
        @items = items # Direct parameter instead of slots (see note in class docs)
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          Constants::TYPOGRAPHY_SCALE[16],
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:body],
          Constants::FONT_FAMILIES[:ui],
          'space-y-2',
          ordered ? 'list-decimal' : 'list-disc',
          'pl-6'
        )
      end

      # Get the HTML tag for this list type
      #
      # @return [Symbol] The list tag (:ul or :ol)
      def list_tag
        @ordered ? :ol : :ul
      end

      private

      def class_names(*classes)
        classes.compact.reject(&:empty?).join(' ')
      end
    end
  end
end
