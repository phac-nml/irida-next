# frozen_string_literal: true

# Module containing styling for checkbox components 🎨
#
# This module provides consistent styling for checkboxes, labels and help text
# using Tailwind CSS classes. It handles different states (hover, focus, disabled)
# and supports both light and dark modes.
module Pathogen
  module Form
    # Provides Tailwind CSS styling helpers for Pathogen checkbox components.
    module CheckboxStyles
      # Generates classes for the checkbox input element ☑️
      #
      # @param user_class [String, nil] Additional classes to merge
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes styles for:
      #   - Layout & dimensions (5x5 with margin)
      #   - Square shape with border
      #   - Colors and backgrounds
      #   - Focus ring effects
      #   - Smooth transitions
      #   - States: checked, hover, disabled
      #   - Dark mode variants
      def checkbox_classes(user_class = nil) # rubocop:disable Metrics/MethodLength
        class_names(
          user_class,
          # Layout & Sizing
          'h-5 w-5 shrink-0 mt-0.5',
          # Shape & Border
          'rounded border-2',
          # Colors & Background
          'text-primary-600 bg-white',
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
          'transition-all duration-200 ease-in-out',
          'focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-primary-500',
          'active:scale-95'
        )
      end

      # Generates classes for the checkbox label 🏷️
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

      # Generates classes for the help text below checkboxes ℹ️
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Provides subtle, smaller text with appropriate spacing
      #       and dark mode support
      def help_text_classes
        'text-sm leading-relaxed text-slate-500 mt-1 dark:text-slate-400'
      end
    end
  end
end
