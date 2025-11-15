# frozen_string_literal: true

require_relative 'constants'

module Pathogen
  module Typography
    # Component for rendering coordinated heading groups with eyebrow and metadata
    #
    # Automatically manages spacing and hierarchy for common patterns like article headers,
    # card titles, and section headings with supporting information.
    #
    # @example Article header
    #   <%= render Pathogen::Typography::HeadingGroup.new(level: 1) do |group| %>
    #     <%= group.with_eyebrow { "Blog Post" } %>
    #     <%= group.with_heading { "Introduction to Typography" } %>
    #     <%= group.with_metadata { "Published January 15, 2024" } %>
    #   <% end %>
    #
    # @example Card header
    #   <%= render Pathogen::Typography::HeadingGroup.new(level: 3, spacing: :compact) do |group| %>
    #     <%= group.with_heading { "Card Title" } %>
    #     <%= group.with_metadata(variant: :muted) { "3 items" } %>
    #   <% end %>
    class HeadingGroup < Component
      renders_one :eyebrow, lambda { |variant: :muted, **system_arguments|
        Eyebrow.new(variant: variant, **system_arguments)
      }

      renders_one :heading, lambda { |**system_arguments|
        Heading.new(level: @level, variant: @heading_variant, responsive: @responsive, **system_arguments)
      }

      renders_one :metadata, lambda { |variant: :muted, **system_arguments|
        Supporting.new(variant: variant, **system_arguments)
      }

      attr_reader :level, :heading_variant, :responsive, :spacing

      # Initialize a new HeadingGroup component
      #
      # @param level [Integer] Heading level (1-6)
      # @param heading_variant [Symbol] Color variant for heading
      # @param responsive [Boolean] Enable responsive sizing for heading
      # @param spacing [Symbol] Spacing style (:default, :compact, :spacious)
      # @param system_arguments [Hash] Additional HTML attributes for wrapper
      def initialize(level: 1, heading_variant: :default, responsive: true, spacing: :default, **system_arguments)
        @level = level
        @heading_variant = heading_variant
        @responsive = responsive
        @spacing = spacing
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          spacing_class
        )
      end

      private

      def spacing_class
        Constants::SPACING_CLASSES[@spacing] || Constants::SPACING_CLASSES[:default]
      end
    end
  end
end
