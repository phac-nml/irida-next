# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering body text paragraphs (16px)
    #
    # Standard body text component for paragraphs and main content with consistent
    # sizing and optimal readability. Supports optional responsive sizing.
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
    # @example Responsive sizing
    #   <%= render Pathogen::Typography::Text.new(responsive: true) do %>
    #     Text that scales from 14px (mobile) to 16px (desktop)
    #   <% end %>
    class Text < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant, :responsive

      # Initialize a new Text component
      #
      # @param tag [Symbol] HTML tag to use (default: :p)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param responsive [Boolean] Enable responsive sizing (default: false)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(tag: DEFAULT_TAG, variant: Shared::DEFAULT_VARIANT, responsive: false, **system_arguments)
        @tag = tag
        @variant = variant
        @responsive = responsive
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          size_classes,
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:body],
          Constants::FONT_FAMILIES[:ui]
        )
      end

      private

      def size_classes
        if @responsive
          responsive_sizes = Constants::TEXT_RESPONSIVE_SIZES[:text]
          "#{responsive_sizes[:mobile]} sm:#{responsive_sizes[:desktop]}"
        else
          Constants::TYPOGRAPHY_SCALE[16]
        end
      end
    end
  end
end
