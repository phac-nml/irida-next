# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering ordered and unordered lists
    #
    # Supports both ordered (ol) and unordered (ul) lists with consistent spacing
    # and styling. Uses slots-based API for rich HTML content.
    #
    # @example Unordered list
    #   <%= render Pathogen::Typography::List.new do |list| %>
    #     <%= list.with_item { "Plain text" } %>
    #     <%= list.with_item { "Item with <strong>bold</strong>".html_safe } %>
    #     <%= list.with_item { link_to "Link", docs_path } %>
    #   <% end %>
    #
    # @example Ordered list
    #   <%= render Pathogen::Typography::List.new(ordered: true) do |list| %>
    #     <%= list.with_item { "Step 1" } %>
    #     <%= list.with_item { "Step 2" } %>
    #   <% end %>
    #
    # @example With variant
    #   <%= render Pathogen::Typography::List.new(variant: :muted) do |list| %>
    #     <%= list.with_item { "Item 1" } %>
    #     <%= list.with_item { "Item 2" } %>
    #   <% end %>
    class List < Component
      include Shared

      renders_many :items, ->(&block) { block }

      DEFAULT_TAG = :ul

      attr_reader :ordered, :variant

      # Initialize a new List component
      #
      # @param ordered [Boolean] Use ordered list (ol) instead of unordered (ul)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(ordered: false, variant: Shared::DEFAULT_VARIANT, **system_arguments)
        @ordered = ordered
        @variant = variant
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
    end
  end
end
