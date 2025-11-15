# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering ordered and unordered lists
    #
    # Supports both ordered (ol) and unordered (ul) lists with consistent spacing
    # and styling. Supports both array-based items and slots-based API for rich content.
    #
    # @example Unordered list (array-based)
    #   <%= render Pathogen::Typography::List.new(items: ["Item 1", "Item 2", "Item 3"]) %>
    #
    # @example Unordered list (slots-based, supports HTML)
    #   <%= render Pathogen::Typography::List.new do |list| %>
    #     <%= list.with_item { "Plain text" } %>
    #     <%= list.with_item { "Item with <strong>bold</strong>".html_safe } %>
    #     <%= list.with_item { link_to "Link", docs_path } %>
    #   <% end %>
    #
    # @example Ordered list
    #   <%= render Pathogen::Typography::List.new(ordered: true, items: ["Step 1", "Step 2"]) %>
    #
    # @example With variant
    #   <%= render Pathogen::Typography::List.new(variant: :muted, items: ["Item 1", "Item 2"]) %>
    class List < Component
      include Shared

      renders_many :items, ->(content = nil, &block) do
        content || block
      end

      DEFAULT_TAG = :ul

      attr_reader :ordered, :variant

      # Initialize a new List component
      #
      # @param ordered [Boolean] Use ordered list (ol) instead of unordered (ul)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param items [Array<String>, nil] Array of list item strings (for backward compatibility)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(ordered: false, variant: Shared::DEFAULT_VARIANT, items: nil, **system_arguments)
        @ordered = ordered
        @variant = variant
        @array_items = items # Store array items for backward compatibility
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

      # Get all items (from array or slots)
      #
      # @return [Array] Combined array of items and slot items
      def all_items
        # If array items provided, convert to array
        # Otherwise use slot items
        @array_items || items
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
