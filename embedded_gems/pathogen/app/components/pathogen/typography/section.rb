# frozen_string_literal: true

require_relative 'constants'

module Pathogen
  module Typography
    # Component for wrapping sections with automatic heading hierarchy validation
    #
    # Helps maintain proper semantic HTML structure by validating heading levels
    # and providing automatic spacing between typography elements. In development
    # mode, warns about heading hierarchy violations (e.g., jumping from h2 to h4).
    #
    # @example Basic section
    #   <%= render Pathogen::Typography::Section.new(level: 2) do %>
    #     <h2>Features</h2>
    #     <p>List of features...</p>
    #   <% end %>
    #
    # @example Section with slot-based heading
    #   <%= render Pathogen::Typography::Section.new(level: 3, spacing: :compact) do |section| %>
    #     <%= section.with_heading { "Card Title" } %>
    #     <p>Card content</p>
    #   <% end %>
    class Section < Component
      renders_one :heading, lambda { |**system_arguments|
        Heading.new(level: @level, **system_arguments)
      }

      attr_reader :level, :spacing

      # Initialize a new Section component
      #
      # @param level [Integer] Heading level (1-6) for this section
      # @param spacing [Symbol] Spacing between elements (:compact, :default, :spacious)
      # @param parent_level [Integer, nil] Parent section's heading level (for validation)
      # @param validate [Boolean] Enable hierarchy validation (default: true in development)
      # @param system_arguments [Hash] Additional HTML attributes for wrapper
      def initialize(level: 2, spacing: :default, parent_level: nil, validate: Rails.env.development?, **system_arguments)
        @level = level
        @spacing = spacing
        @parent_level = parent_level
        @validate = validate
        @system_arguments = system_arguments

        validate_heading_hierarchy if @validate

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          spacing_class
        )

        @system_arguments[:role] = 'region' if @level == 2
        @system_arguments[:'aria-labelledby'] = system_arguments[:id] if system_arguments[:id]
      end

      private

      def spacing_class
        section_spacing_key = "section_#{@spacing}".to_sym
        Constants::SPACING_CLASSES[section_spacing_key] || Constants::SPACING_CLASSES[:section_default]
      end

      def validate_heading_hierarchy
        return unless @parent_level

        # Heading should be exactly one level deeper than parent
        expected_level = @parent_level + 1

        return if @level == expected_level

        # Allow skipping to same level (sibling sections)
        return if @level == @parent_level

        # Warn about hierarchy violations
        Rails.logger.warn(
          "[Pathogen::Typography::Section] Heading hierarchy violation: " \
          "Expected level #{expected_level} (parent: h#{@parent_level}), got level #{@level}. " \
          "This may cause accessibility issues. Consider adjusting heading levels."
        )
      end
    end
  end
end
