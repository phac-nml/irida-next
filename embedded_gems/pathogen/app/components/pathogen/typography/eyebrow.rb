# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering eyebrow text (12px, uppercase)
    #
    # Small, uppercase text that appears above headings. Perfect for categories,
    # labels, or context that helps users understand content hierarchy.
    #
    # @example Basic eyebrow
    #   <%= render Pathogen::Typography::Eyebrow.new do %>
    #     Featured Article
    #   <% end %>
    #
    # @example With variant
    #   <%= render Pathogen::Typography::Eyebrow.new(variant: :muted) do %>
    #     Category Label
    #   <% end %>
    class Eyebrow < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant

      # Initialize a new Eyebrow component
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
          Constants::TYPOGRAPHY_SCALE[12],
          'uppercase',
          Constants::LETTER_SPACING[:wider],
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:body],
          'font-semibold',
          Constants::FONT_FAMILIES[:ui]
        )
      end
    end
  end
end
