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
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @role = options.delete(:role)

        # Support Rails-style nested ARIA hash e.g., aria: { describedby: 'id' }
        process_nested_aria(options.delete(:aria))

        # 🚫 Remove unsupported top-level aria_* options to avoid leaking invalid attributes
        strip_disallowed_aria_options!(options)
      end

      # Normalizes and applies Rails-style nested ARIA options
      # @param user_aria [Hash, nil]
      def process_nested_aria(user_aria)
        @aria_user = nil
        return unless user_aria.is_a?(Hash)

        aria = normalize_user_aria(user_aria)
        @aria_user = aria
        apply_nested_aria_values(aria)
        add_user_describedby(aria)
      end

      # Symbolize keys for the provided aria hash
      # @param user_aria [Hash]
      # @return [Hash]
      def normalize_user_aria(user_aria)
        user_aria.transform_keys(&:to_sym)
      end

      # Apply precedence for supported nested aria keys
      # @param aria [Hash]
      # @return [void]
      def apply_nested_aria_values(aria)
        @aria_label = aria[:label] if aria.key?(:label)
        @aria_labelledby = aria[:labelledby] if aria.key?(:labelledby)
        @aria_live = aria[:live] if aria.key?(:live)
        @controls = aria[:controls] if aria.key?(:controls)
      end

      # Merge user-provided describedby with top-level described_by
      # @param aria [Hash]
      # @return [void]
      def add_user_describedby(aria)
        return if (user_describedby = aria[:describedby]).blank?

        @described_by = [@described_by, user_describedby].compact.join(' ')
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

      # Removes any unsupported aria_* style options from remaining HTML options.
      # We only support nested ARIA via `aria: { ... }`.
      # @param options [Hash]
      # @return [void]
      def strip_disallowed_aria_options!(options)
        return if options.blank?

        # Remove common top-level aria_* keys
        disallowed_keys = options.keys.select do |k|
          k.to_s.start_with?('aria_') || %w[aria-label aria-labelledby aria-live].include?(k.to_s)
        end
        disallowed_keys.each { |k| options.delete(k) }
      end
    end
  end
end
