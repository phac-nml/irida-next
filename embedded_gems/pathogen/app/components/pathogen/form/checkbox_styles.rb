# frozen_string_literal: true

# Module containing styling for checkbox components 🎨
#
# This module provides consistent styling for checkboxes, labels and help text
# using Tailwind CSS classes. It handles different states (hover, disabled)
# and supports both light and dark modes.
module Pathogen
  module Form
    # Provides Tailwind CSS styling helpers for Pathogen checkbox components.
    module CheckboxStyles
      include FormStyles
      # Generates classes for the checkbox input element ☑️
      #
      # @param user_class [String, nil] Additional classes to merge
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes styles for:
      #   - Layout & dimensions (5x5 with margin)
      #   - Square shape with border
      #   - Colors and backgrounds
      #   - Smooth transitions
      #   - States: checked, hover, disabled
      #   - Dark mode variants
      def checkbox_classes(user_class = nil)
        class_names(
          user_class,
          # Square shape
          'rounded',
          # Shared base control classes
          *control_base_classes
        )
      end
    end
  end
end
