# frozen_string_literal: true

module Pathogen
  module Form
    # Utility module for extracting and processing checkbox component options.
    #
    # This module provides focused methods for parsing constructor parameters
    # and separating them into logical groups (basic, accessibility, behavior).
    # It helps reduce complexity in the main Checkbox class constructor.
    #
    # @api private
    # @since 1.0.0
    module CheckboxOptionExtractor
      # Extracts and processes options from the constructor parameters.
      #
      # Separates standard options from HTML attributes and processes
      # accessibility, behavior, and styling options.
      #
      # @param options [Hash] the options hash from constructor
      # @return [void]
      def extract_options!(options)
        extract_basic_options(options)
        extract_accessibility_options(options)
        extract_behavior_options(options)
        @html_options = options # Store remaining options
      end

      private

      # Extracts basic options from the constructor parameters.
      #
      # Processes fundamental checkbox options like input name, label,
      # checked state, disabled state, CSS classes, and text content.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      def extract_basic_options(options)
        @input_name = options.delete(:input_name)
        @label = options.delete(:label)
        @checked = options.delete(:checked) || false
        @disabled = options.delete(:disabled) || false
        @class = options.delete(:class)
        @help_text = options.delete(:help_text)
        @error_text = options.delete(:error_text)
      end

      # Extracts accessibility-related options from constructor parameters.
      #
      # Processes ARIA attributes, roles, and accessibility-specific
      # configuration options for screen readers and assistive technology.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      def extract_accessibility_options(options)
        @aria_label = options.delete(:aria_label)
        @described_by = options.delete(:described_by)
        @aria_labelledby = options.delete(:aria_labelledby)
        @controls = options.delete(:controls)
        @role = options.delete(:role)
        @aria_live = options.delete(:aria_live)
      end

      # Extracts behavior and interaction options from constructor parameters.
      #
      # Processes language settings, event handlers, and user feedback
      # messages for checkbox state changes.
      #
      # @param options [Hash] the options hash to process
      # @return [void]
      def extract_behavior_options(options)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @selected_message = options.delete(:selected_message)
        @deselected_message = options.delete(:deselected_message)
      end
    end
  end
end
