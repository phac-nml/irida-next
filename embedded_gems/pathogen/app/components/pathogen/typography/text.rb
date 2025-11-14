# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering body text paragraphs (16px)
    #
    # Standard body text component for paragraphs and main content with consistent
    # sizing and optimal readability.
    #
    # @example Basic paragraph
    #   <%= render Pathogen::Typography::Text.new do %>
    #     This is body text at 16px.
    #   <% end %>
    #
    # @example With color variant
    #   <%= render Pathogen::Typography::Text.new(variant: :muted) do %>
    #     Secondary information
    #   <% end %>
    #
    # @example Custom HTML tag
    #   <%= render Pathogen::Typography::Text.new(tag: :div) do %>
    #     Text rendered as a div
    #   <% end %>
    class Text < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant

      # Initialize a new Text component
      #
      # @param tag [Symbol] HTML tag to use (default: :p)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(tag: DEFAULT_TAG, variant: Shared::DEFAULT_VARIANT, **system_arguments)
        @tag = tag
        @variant = variant
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          Constants::TYPOGRAPHY_SCALE[16],
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:body],
          Constants::FONT_FAMILIES[:ui]
        )
      end

      private

      def class_names(*classes)
        classes.compact.reject(&:empty?).join(' ')
      end
    end
  end
end
