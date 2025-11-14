# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering supporting text (14px) - captions, labels, metadata
    #
    # Smaller than body text, used for captions, labels, and secondary information.
    #
    # @example Caption
    #   <%= render Pathogen::Typography::Supporting.new do %>
    #     Image caption text
    #   <% end %>
    #
    # @example Muted variant
    #   <%= render Pathogen::Typography::Supporting.new(variant: :muted) do %>
    #     Published on January 15, 2024
    #   <% end %>
    class Supporting < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant

      # Initialize a new Supporting component
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
          Constants::TYPOGRAPHY_SCALE[14],
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
