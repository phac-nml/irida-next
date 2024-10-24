# frozen_string_literal: true

module Pathogen
  # :nodoc:
  class Classify
    # LOOKUP is a constant that stores utility classes for the Pathogen framework.
    # It's defined in the Pathogen::Classify::Utilities module and contains
    # a hash of utility classes organized by their purpose (e.g., spacing, colors, etc.).
    # This constant is used throughout the Classify class to process and validate
    # class names passed to components.
    LOOKUP = Pathogen::Classify::Utilities::UTILITIES

    class << self
      # Processes the given arguments and returns a hash with class and style attributes
      # @param args [Hash] The arguments to process
      # @return [Hash] A hash containing :class and :style keys
      def call(args = {})
        style, classes = process_arguments(args)

        {
          class: classes.blank? ? nil : classes.join(' '),
          style: style.presence
        }
      end

      private

      # Processes the arguments and separates them into style and classes
      # @param args [Hash] The arguments to process
      # @return [Array] An array containing the style and classes
      def process_arguments(args)
        style = nil
        classes = []

        args.each do |key, val|
          case key
          when :classes
            classes.unshift(validated_class_names(val)) if validated_class_names(val)
          when :style
            style = val
          else
            process_lookup(key, val, classes)
          end
        end

        [style, classes]
      end

      # Processes a lookup key-value pair and adds appropriate classes
      # @param key [Symbol] The lookup key
      # @param val [Object] The value associated with the key
      # @param classes [Array] The array to store the resulting classes
      def process_lookup(key, val, classes)
        return unless LOOKUP[key]

        if val.is_a?(Array)
          process_array_value(key, val, classes)
        else
          process_single_value(key, val, classes)
        end
      end

      # Processes an array value for a given key and adds appropriate classes
      # @param key [Symbol] The lookup key
      # @param val [Array] The array value to process
      # @param classes [Array] The array to store the resulting classes
      def process_array_value(key, val, classes)
        val.each_with_index do |item, index|
          next if item.nil?

          found = find_or_validate(key, item, index)
          classes << found if found
        end
      end

      # Processes a single value for a given key and adds the appropriate class
      # @param key [Symbol] The lookup key
      # @param val [Object] The value to process
      # @param classes [Array] The array to store the resulting class
      def process_single_value(key, val, classes)
        return if val.nil?

        found = find_or_validate(key, val, 0)
        classes << found if found
      end

      # Finds a value in the LOOKUP or validates it
      # @param key [Symbol] The lookup key
      # @param item [Object] The item to find or validate
      # @param index [Integer] The index in the breakpoints array
      # @return [String, nil] The found or validated class, or nil if not found/valid
      def find_or_validate(key, item, index)
        LOOKUP.dig(key, item, index) || validate(key, item, index)
      rescue StandardError
        validate(key, item, index)
      end

      # Validates a value for a given key and breakpoint
      # @param key [Symbol] The lookup key
      # @param val [Object] The value to validate
      # @param brk [Integer] The breakpoint index
      # @return [String, nil] The validated class or nil if not valid
      def validate(key, val, brk)
        brk_str = Pathogen::Classify::Utilities::BREAKPOINTS[brk]
        Pathogen::Classify::Utilities.validate(key, val, brk_str)
      end

      # Validates and returns the given class names
      # @param classes [String] The class names to validate
      # @return [String, nil] The validated class names or nil if blank
      def validated_class_names(classes)
        return if classes.blank?

        if raise_on_invalid_options? && !ENV['PATHOGEN_WARNINGS_DISABLED']
          invalid_class_names =
            classes.split.each_with_object([]) do |class_name, memo|
              memo << class_name if Pathogen::Classify::Validation.invalid?(class_name)
            end

          if invalid_class_names.any?
            raise ArgumentError, "Invalid Pathogen CSS class #{'name'.pluralize(invalid_class_names.length)} " \
                                 "detected: #{invalid_class_names.to_sentence}. " \
                                 'Please use valid Pathogen classes. ' \
                                 'This warning is not raised in production. ' \
                                 'Set PATHOGEN_WARNINGS_DISABLED=1 to disable.'
          end
        end

        classes
      end

      # Checks if the application is configured to raise on invalid options
      # @return [Boolean] True if configured to raise on invalid options, false otherwise
      def raise_on_invalid_options?
        Rails.application.config._view_components.raise_on_invalid_options
      end
    end
  end
end
