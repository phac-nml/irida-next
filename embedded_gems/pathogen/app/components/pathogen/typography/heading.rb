# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering semantic headings (h1-h6) with responsive sizing
    #
    # Headings automatically scale between mobile and desktop sizes, use semantic HTML,
    # and support color variants for different contexts.
    #
    # @example Basic heading
    #   <%= render Pathogen::Typography::Heading.new(level: 1) do %>
    #     Page Title
    #   <% end %>
    #
    # @example With color variant
    #   <%= render Pathogen::Typography::Heading.new(level: 2, variant: :muted) do %>
    #     Section Heading
    #   <% end %>
    #
    # @example Disable responsive sizing
    #   <%= render Pathogen::Typography::Heading.new(level: 3, responsive: false) do %>
    #     Fixed Size Heading
    #   <% end %>
    class Heading < Component
      include Shared

      DEFAULT_LEVEL = 1

      attr_reader :level, :variant, :responsive

      # Initialize a new Heading component
      #
      # @param level [Integer] Heading level (1-6)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param responsive [Boolean] Enable responsive sizing (default: true)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(level:, variant: Shared::DEFAULT_VARIANT, responsive: true, **system_arguments)
        @level = normalize_level(level)
        @variant = variant
        @responsive = responsive
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          size_classes,
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:heading],
          letter_spacing_class,
          Constants::FONT_FAMILIES[:ui]
        )
      end

      # Get the HTML tag for this heading level
      #
      # @return [Symbol] The heading tag (:h1, :h2, etc.)
      def heading_tag
        "h#{@level}".to_sym
      end

      private

      def normalize_level(level)
        normalized = case level
                      when Integer
                        level
                      when String
                        level.to_i
                      else
                        level
                      end
        fetch_or_fallback((1..6).to_a, normalized, DEFAULT_LEVEL)
      end

      def size_classes
        if @responsive
          mobile_class = Constants::RESPONSIVE_SIZES[@level][:mobile]
          desktop_class = Constants::RESPONSIVE_SIZES[@level][:desktop]
          "#{mobile_class} sm:#{desktop_class}"
        else
          Constants::RESPONSIVE_SIZES[@level][:mobile]
        end
      end

      def letter_spacing_class
        case @level
        when 1, 2
          Constants::LETTER_SPACING[:tight]
        else
          Constants::LETTER_SPACING[:normal]
        end
      end

      def class_names(*classes)
        classes.compact.reject(&:empty?).join(' ')
      end
    end
  end
end
