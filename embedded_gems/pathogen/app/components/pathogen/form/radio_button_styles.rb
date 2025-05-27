# frozen_string_literal: true

# Module containing styling for radio button components 🎨
#
# This module provides consistent styling for radio buttons, labels and help text
# using Tailwind CSS classes. It handles different states (hover, focus, disabled)
# and supports both light and dark modes.
module Pathogen
  module Form
    module RadioButtonStyles
      # Generates classes for the radio button input element 🔘
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes styles for:
      #   - Layout & dimensions (5x5 with margin)
      #   - Circular shape with border
      #   - Colors and backgrounds
      #   - Focus ring effects
      #   - Smooth transitions
      #   - States: checked, hover, disabled
      #   - Dark mode variants
      def radio_button_classes
        class_names(
          @options[:class],
          # Layout & Sizing
          'h-5 w-5 shrink-0 mt-0.5',
          # Shape & Border
          'rounded-full border-2',
          # Colors & Background
          'text-primary-600 bg-white',
          # Focus States
          'focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2',
          # Cursor & Interaction
          'cursor-pointer transition-colors duration-200 ease-in-out',
          # Checked State
          'checked:border-primary-500 checked:bg-primary-500',
          # Hover State
          'hover:border-primary-500',
          # Disabled State
          'disabled:opacity-50 disabled:cursor-not-allowed',
          'disabled:border-slate-200 disabled:bg-slate-100',
          # Dark Mode
          'dark:border-slate-600 dark:bg-slate-700',
          'dark:checked:bg-primary-600 dark:checked:border-primary-500',
          'dark:disabled:bg-slate-800 dark:disabled:border-slate-700',
          'dark:disabled:checked:bg-slate-600',
          'dark:focus:ring-primary-400'
        )
      end

      # Generates classes for the radio button label 🏷️
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes styles for:
      #   - Typography (small, medium weight)
      #   - Cursor interaction
      #   - Disabled state
      #   - Dark mode support
      def label_classes
        class_names(
          # Typography
          'text-sm font-medium text-slate-900',
          # Cursor
          'cursor-pointer',
          # Disabled State
          'disabled:cursor-not-allowed disabled:opacity-50',
          # Dark Mode
          'dark:text-slate-100'
        )
      end

      # Generates classes for the help text below radio buttons ℹ️
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Provides subtle, smaller text with appropriate spacing
      #       and dark mode support
      def help_text_classes
        'text-sm text-slate-500 mt-1 dark:text-slate-400'
      end
    end
  end
end
