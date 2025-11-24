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
        system_arguments[:id] ||= heading_dom_id
        Heading.new(level: @level, **system_arguments)
      }

      attr_reader :level, :spacing

      DEFAULT_LEVEL = 2

      # Initialize a new Section component
      #
      # @param level [Integer] Heading level (1-6) for this section
      # @param parent_level [Integer, nil] Parent section's heading level (for validation)
      # @param spacing [Symbol] Spacing between elements (:compact, :default, :spacious)
      # @param validate [Boolean] Enable hierarchy validation (default: true in development)
      # @param heading_id [String, nil] Explicit DOM id for the heading slot
      # @param options [Hash] Additional HTML attributes for wrapper plus overrides listed above
      def initialize(level: 2, parent_level: nil, **options)
        @level = normalize_level(level)
        @parent_level = normalize_level(parent_level) if parent_level
        assign_options(options)

        validate_heading_hierarchy if @validate

        @system_arguments[:class] = class_names(
          @system_arguments[:class],
          spacing_class
        )

        @system_arguments[:role] = 'region' if @level == 2
        assign_labelledby
      end

      private

      attr_reader :heading_id

      def normalize_level(level)
        return nil if level.nil?

        normalized = level.is_a?(String) ? level.to_i : level
        fetch_or_fallback((1..6).to_a, normalized, DEFAULT_LEVEL)
      end

      def assign_options(options)
        @spacing = options.key?(:spacing) ? options.delete(:spacing) : :default
        @validate = options.key?(:validate) ? options.delete(:validate) : Rails.env.development?
        @heading_id = options.delete(:heading_id)
        @system_arguments = options
        @heading_id = derive_heading_id if @heading_id.nil?
      end

      def heading_dom_id
        @heading_id
      end

      def spacing_class
        section_spacing_key = :"section_#{@spacing}"
        Constants::SPACING_CLASSES[section_spacing_key] || Constants::SPACING_CLASSES[:section_default]
      end

      def derive_heading_id
        return unless @system_arguments[:id]

        "#{@system_arguments[:id]}-heading"
      end

      def assign_labelledby
        return unless heading_dom_id

        @system_arguments[:'aria-labelledby'] ||= heading_dom_id
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
          '[Pathogen::Typography::Section] Heading hierarchy violation: ' \
          "Expected level #{expected_level} (parent: h#{@parent_level}), got level #{@level}. " \
          'This may cause accessibility issues. Consider adjusting heading levels.'
        )
      end
    end
  end
end
