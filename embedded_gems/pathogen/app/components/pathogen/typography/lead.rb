# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering lead paragraphs (20px)
    #
    # Larger introductory paragraphs used at the start of sections to draw attention
    # and provide context. Has a comfortable line-height for optimal readability.
    #
    # @example Lead paragraph
    #   <%= render Pathogen::Typography::Lead.new do %>
    #     This is a lead paragraph that introduces the section.
    #   <% end %>
    #
    # @example With variant
    #   <%= render Pathogen::Typography::Lead.new(variant: :muted) do %>
    #     Muted lead paragraph
    #   <% end %>
    class Lead < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant

      # Initialize a new Lead component
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
          Constants::TYPOGRAPHY_SCALE[20],
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:relaxed],
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
