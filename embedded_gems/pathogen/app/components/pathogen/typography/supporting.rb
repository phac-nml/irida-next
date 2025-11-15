# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering supporting text (14px) - captions, labels, metadata
    #
    # Smaller than body text, used for captions, labels, and secondary information.
    # Supports optional responsive sizing.
    #
    # @example Caption
    #   <%= render Pathogen::Typography::Supporting.new do %>
    #     Image caption text
    #   <% end %>
    #
    # @example Responsive sizing
    #   <%= render Pathogen::Typography::Supporting.new(responsive: true, variant: :muted) do %>
    #     Scales from 12px (mobile) to 14px (desktop)
    #   <% end %>
    class Supporting < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant, :responsive

      # Initialize a new Supporting component
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
          responsive_sizes = Constants::TEXT_RESPONSIVE_SIZES[:supporting]
          "#{responsive_sizes[:mobile]} sm:#{responsive_sizes[:desktop]}"
        else
          Constants::TYPOGRAPHY_SCALE[14]
        end
      end

      def class_names(*classes)
        classes.compact.reject(&:empty?).join(' ')
      end
    end
  end
end
