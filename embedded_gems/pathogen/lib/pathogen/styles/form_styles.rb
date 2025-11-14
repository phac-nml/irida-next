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
        pathogen_classes = build_checkbox_classes(options)
        options = remove_table_marker(options)
        options[:class] = merge_classes(pathogen_classes, options[:class])
        options
      end

      private

      # Build the list of checkbox classes based on context
      def build_checkbox_classes(options)
        classes = CHECKBOX_CLASSES.dup
        classes.concat(CHECKBOX_TABLE_CLASSES) if options.dig(:data, :table)
        classes
      end

      # Remove table marker from data attributes
      def remove_table_marker(options)
        return options unless options.dig(:data, :table)

        options[:data] = options[:data].except(:table)
        options
      end

      # Merge user classes with Pathogen classes
      def merge_classes(pathogen_classes, user_classes)
        return pathogen_classes if user_classes.blank?

        user_array = user_classes.is_a?(Array) ? user_classes : [user_classes.to_s]
        pathogen_classes + user_array
      end
    end
  end
end
