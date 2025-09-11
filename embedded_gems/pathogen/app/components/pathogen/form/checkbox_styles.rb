# frozen_string_literal: true

module Pathogen
  module Form
    # Styling module specifically for checkbox components.
    #
    # Provides comprehensive Tailwind CSS styling for checkbox inputs,
    # labels, help text, and container elements with full accessibility
    # and responsive design support.
    #
    # @since 2.0.0
    module CheckboxStyles
      include FormStyles

      # Generates CSS classes for the checkbox input element.
      #
      # @param user_class [String, nil] additional user-provided classes
      # @return [String] space-separated Tailwind CSS classes
      def checkbox_classes(user_class = nil)
        class_names(
          user_class,
          'rounded', # Square shape with rounded corners
          *control_base_classes
        )
      end

      # Container classes for checkbox layouts.
      #
      # @return [String] CSS classes for the main container
      def checkbox_container_classes
        'flex flex-col'
      end

      # Container classes for checkbox and label grouping.
      #
      # @return [String] CSS classes for input/label container
      def checkbox_input_container_classes
        'flex items-start gap-3'
      end

      # Container classes for help text and descriptions.
      #
      # @return [String] CSS classes for help text container
      def checkbox_help_container_classes
        # Align help text with label (checkbox width 1rem + gap-3 0.75rem = 1.75rem)
        # and add a little extra space below to separate stacked checkboxes.
        'mt-1 mb-2 pl-7'
      end

      # Container classes for aria-only checkboxes (no visible label).
      #
      # @return [String] CSS classes for aria-only help container
      def checkbox_aria_help_container_classes
        'mt-1 mb-2'
      end

      # CSS classes for enhanced description text.
      #
      # @return [String] CSS classes for description elements
      def description_classes
        'sr-only'
      end

      # CSS classes for screen-reader-only help text.
      #
      # @return [String] CSS classes for sr-only help text
      def help_text_sr_only_classes
        'sr-only'
      end
    end
  end
end
