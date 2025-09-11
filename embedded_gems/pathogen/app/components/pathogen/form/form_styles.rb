# frozen_string_literal: true

# Shared styling helpers for form controls 🎨
#
# Provides common TailwindCSS class helpers used across form elements
# (checkboxes, radio buttons, etc.), ensuring consistent typography,
# spacing, disabled states, and dark mode support.
module Pathogen
  module Form
    # Common Tailwind CSS styling helpers for Pathogen form components.
    module FormStyles
      # Label classes used across form controls 🏷️
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Includes typography, pointer behavior, disabled state and dark mode
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

      # Help text classes used beneath form controls ℹ️
      #
      # @return [String] Space-separated Tailwind CSS classes
      # @note Subtle text with spacing and dark mode
      def help_text_classes
        'text-sm leading-relaxed text-slate-500 mt-1 dark:text-slate-400'
      end

      # Base classes for interactive form inputs (checkbox, radio, etc.)
      #
      # @return [Array<String>] Tailwind classes common to all controls
      # @example
      #   class_names(user_class, 'rounded', *control_base_classes)
      def control_base_classes
        control_layout_classes + control_state_classes + control_dark_classes
      end

      private

      # Base layout/interaction classes
      def control_layout_classes
        [
          'h-5 w-5 shrink-0 mt-0.5',
          'border-2',
          'text-primary-600 bg-white',
          'cursor-pointer transition-colors duration-200 ease-in-out',
          'transition-all duration-200 ease-in-out',
          'active:scale-95'
        ]
      end

      # State classes (checked/hover/disabled)
      def control_state_classes
        [
          'checked:border-primary-500 checked:bg-primary-500',
          'hover:border-primary-500',
          'disabled:opacity-50 disabled:cursor-not-allowed',
          'disabled:border-slate-200 disabled:bg-slate-100'
        ]
      end

      # Dark mode classes
      def control_dark_classes
        [
          'dark:border-slate-600 dark:bg-slate-700',
          'dark:checked:bg-primary-600 dark:checked:border-primary-500',
          'dark:disabled:bg-slate-800 dark:disabled:border-slate-700',
          'dark:disabled:checked:bg-slate-600'
        ]
      end
    end
  end
end
