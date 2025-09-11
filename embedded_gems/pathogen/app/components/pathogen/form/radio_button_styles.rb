# frozen_string_literal: true

module Pathogen
  module Form
    # Styling module specifically for radio button components.
    #
    # Provides comprehensive Tailwind CSS styling for radio button inputs,
    # labels, help text, and container elements with full accessibility
    # and responsive design support.
    #
    # @since 2.0.0
    module RadioButtonStyles
      include FormStyles

      # Generates CSS classes for the radio button input element.
      #
      # @param user_class [String, nil] additional user-provided classes
      # @return [String] space-separated Tailwind CSS classes
      def radio_button_classes(user_class = nil)
        class_names(
          user_class,
          'rounded-full', # Circular shape
          *control_base_classes
        )
      end

      # Container classes for radio button layouts.
      #
      # @return [String] CSS classes for the main container
      def radio_button_container_classes
        'flex flex-col'
      end

      # Container classes for radio button and label grouping.
      #
      # @return [String] CSS classes for input/label container
      def radio_button_input_container_classes
        'flex items-center gap-3'
      end

      # Container classes for help text and descriptions.
      #
      # @return [String] CSS classes for help text container
      def radio_button_help_container_classes
        'mt-1 ml-8'
      end
    end
  end
end
