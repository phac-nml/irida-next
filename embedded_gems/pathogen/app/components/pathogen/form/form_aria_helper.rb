# frozen_string_literal: true

module Pathogen
  module Form
    # Helper module for ARIA attribute construction in form components.
    #
    # This module provides focused methods for building comprehensive ARIA
    # attributes for form inputs, including describedby relationships and
    # accessibility labels.
    #
    # @since 2.0.0
    module FormAriaHelper
      private

      # Builds ARIA attributes hash.
      #
      # @return [Hash] ARIA attributes hash
      def aria_attributes
        aria = build_basic_aria_attributes
        add_describedby_to_aria(aria)
        aria.any? ? { aria: aria } : {}
      end

      # Builds basic ARIA attributes without describedby.
      #
      # @return [Hash] basic ARIA attributes
      def build_basic_aria_attributes
        aria = {}
        aria[:label] = @aria_label if @aria_label.present?
        aria[:labelledby] = @aria_labelledby if @aria_labelledby.present?
        aria[:live] = @aria_live if @aria_live.present?
        aria[:controls] = @controls if @controls.present?
        aria
      end

      # Adds describedby attribute to ARIA hash if needed.
      #
      # @param aria [Hash] the ARIA attributes hash to modify
      # @return [void]
      def add_describedby_to_aria(aria)
        describedby_value = build_describedby_value
        aria[:describedby] = describedby_value if describedby_value.present?
      end

      # Builds the describedby attribute value from multiple sources.
      #
      # @return [String, nil] space-separated describedby IDs or nil
      def build_describedby_value
        parts = collect_describedby_parts
        parts.join(' ') if parts.any?
      end

      # Collects all describedby parts from various sources.
      #
      # @return [Array<String>] array of describedby IDs
      def collect_describedby_parts
        [
          @aria_describedby,
          help_text_describedby,
          controls_describedby
        ].compact
      end

      # Returns help text describedby ID if help text is present.
      #
      # @return [String, nil] help text ID or nil
      def help_text_describedby
        help_text_id if @help_text.present?
      end

      # Returns controls describedby ID if controls are present.
      #
      # @return [String, nil] controls description ID or nil
      def controls_describedby
        "#{input_id}_description" if @controls.present?
      end
    end
  end
end
