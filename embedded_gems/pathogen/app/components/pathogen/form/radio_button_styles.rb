# frozen_string_literal: true

# Module containing styling for radio button components 🎨
#
# This module provides consistent styling for radio buttons, labels and help text
# using Tailwind CSS classes. It handles different states (hover, focus, disabled)
# and supports both light and dark modes.
module Pathogen
  module Form
    # Provides Tailwind CSS styling helpers for Pathogen radio button components.
    module RadioButtonStyles
      include FormStyles
      # Generates classes for the radio button input element 🔘
      #
      # @param user_class [String, nil] Additional classes to merge
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes styles for:
      #   - Layout & dimensions (5x5 with margin)
      #   - Circular shape with border
      #   - Colors and backgrounds
      #   - Focus ring effects
      #   - Smooth transitions
      #   - States: checked, hover, disabled
      #   - Dark mode variants
      def radio_button_classes(user_class = nil)
        class_names(
          user_class,
          # Circular shape
          'rounded-full',
          # Shared base control classes
          *control_base_classes
        )
      end
    end
  end
end
