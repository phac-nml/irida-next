# frozen_string_literal: true

module Pathogen
  module Form
    # Helper module for extracting and processing form component options.
    #
    # This module provides focused methods for parsing constructor parameters
    # and separating them into logical groups (basic, accessibility, behavior).
    # It helps reduce complexity in form component constructors.
    #
    # @since 2.0.0
    module FormOptionExtractor
      private

      # Extracts options from the constructor and validates requirements.
      #
      # @param options [Hash] the options to extract
      # @return [void]
      def extract_and_validate_options!(options)
        extract_basic_options!(options)
        extract_accessibility_options!(options)
        extract_behavior_options!(options)
        @html_options = options # Store any remaining options
        validate_accessibility_requirements!
      end

      # Extracts basic form options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_basic_options!(options)
        @input_name = options.delete(:input_name)
        @id = options.delete(:id)
        @label = options.delete(:label)
        @checked = options.delete(:checked) || false
        @disabled = options.delete(:disabled) || false
        @class = options.delete(:class)
        @help_text = options.delete(:help_text)
        @error_text = options.delete(:error_text)
      end

      # Extracts accessibility-related options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_accessibility_options!(options)
        @role = options.delete(:role)
        process_aria_options!(options)
      end

      # Extracts behavior and interaction options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_behavior_options!(options)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @selected_message = options.delete(:selected_message)
        @deselected_message = options.delete(:deselected_message)
      end

      # Processes nested ARIA options and sets instance variables.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def process_aria_options!(options)
        aria = options.delete(:aria)
        return unless aria.is_a?(Hash)

        aria = aria.transform_keys(&:to_sym)
        @aria_label = aria[:label]
        @aria_labelledby = aria[:labelledby]
        @aria_describedby = aria[:describedby]
        @aria_live = aria[:live]
        @controls = aria[:controls]
      end

      # Validates that accessibility requirements are met.
      #
      # @raise [ArgumentError] if no accessible label is provided
      # @return [void]
      def validate_accessibility_requirements!
        # Radio buttons don't require labels if they're part of a fieldset
        return if input_type == 'radio' && @label.blank?
        return unless @label.blank? && @aria_label.blank? && @aria_labelledby.blank?

        raise ArgumentError,
              "Form component requires either 'label', " \
              "'aria: { label: ... }', or 'aria: { labelledby: ... }' " \
              'for accessibility compliance'
      end
    end
  end
end
