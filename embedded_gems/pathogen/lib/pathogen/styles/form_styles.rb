# frozen_string_literal: true

module Pathogen
  module Styles
    # Shared form styling constants and utility methods
    #
    # This module provides shared styling constants and utility methods
    # that can be used across different form components and helpers.
    module FormStyles
      # Common styling classes for checkboxes
      CHECKBOX_CLASSES = [
        'size-6', # 24px - better accessibility
        'bg-white',
        '!border-slate-300',
        'rounded-sm', # Consistent with style guide for form elements
        'cursor-pointer',
        'transition-all',
        'duration-150',
        'ease-in-out',
        'hover:bg-slate-200',
        'hover:border-slate-400',
        'disabled:opacity-50',
        'disabled:cursor-not-allowed',
        'dark:bg-slate-700',
        'dark:border-slate-600',
        'dark:hover:bg-slate-600',
        'dark:hover:border-slate-500'
      ].freeze

      # Classes to add when checkbox is in a table context
      CHECKBOX_TABLE_CLASSES = [
        '-mt-0.5', # Small negative top margin to visually center
        'mb-0', # Remove bottom margin
        'flex-shrink-0', # Prevent compression in flex containers
        'self-center' # Align self to center in flex container
      ].freeze

      # Apply Pathogen styling to checkbox options
      #
      # @param options [Hash] Options for the checkbox
      # @return [Hash] Options with Pathogen styling applied
      def apply_pathogen_styling(options)
        # Start with a copy of the base checkbox classes
        pathogen_classes = CHECKBOX_CLASSES.dup

        # Handle table context if specified
        if options[:table]
          pathogen_classes.concat(CHECKBOX_TABLE_CLASSES)
          options = options.except(:table)
        end

        # Merge custom classes with Pathogen classes
        if options[:class].present?
          user_classes = options[:class].is_a?(Array) ? options[:class] : [options[:class].to_s]
          options[:class] = pathogen_classes + user_classes
        else
          options[:class] = pathogen_classes
        end

        options
      end
    end
  end
end
