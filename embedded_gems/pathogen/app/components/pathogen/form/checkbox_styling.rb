# frozen_string_literal: true

module Pathogen
  module Form
    # Shared styling logic for Pathogen checkbox components
    #
    # This module provides consistent styling and HTML attribute handling
    # for both CheckBox and CheckBoxTag components.
    #
    # @since 3.1.0
    module CheckboxStyling
      extend ActiveSupport::Concern

      private

      # Provides CSS classes for the checkbox input element with Pathogen styling.
      #
      # @return [String] complete CSS class string for the input
      def checkbox_classes # rubocop:disable Metrics/MethodLength
        base_classes = [
          'size-6', # 24px - better accessibility
          'text-primary-600',
          'bg-slate-100',
          'border-slate-300',
          'rounded-sm', # Consistent with style guide for form elements
          'cursor-pointer',
          # Transitions for smooth animations
          'transition-all',
          'duration-150',
          'ease-in-out',
          # Hover states
          'hover:bg-slate-200',
          'hover:border-slate-400',
          # Disabled states
          'disabled:opacity-50',
          'disabled:cursor-not-allowed',
          # Dark mode variants
          'dark:bg-slate-700',
          'dark:border-slate-600',
          'dark:hover:bg-slate-600',
          'dark:hover:border-slate-500'
        ]

        # Add table-specific classes if this checkbox is in a table context
        if @html_options[:table]
          base_classes << '-mt-0.5' # Small negative top margin to visually center
          base_classes << 'mb-0' # Remove bottom margin
          base_classes << 'flex-shrink-0' # Prevent compression in flex containers
          base_classes << 'self-center' # Align self to center in flex container
        end

        user_classes = @html_options[:class]

        if user_classes.present?
          # Handle both string and array classes
          user_class_string = user_classes.is_a?(Array) ? user_classes.join(' ') : user_classes.to_s
          "#{base_classes.join(' ')} #{user_class_string}"
        else
          base_classes.join(' ')
        end
      end

      # Builds common attributes for checkbox input tags
      #
      # @return [Hash] attributes for the checkbox input tag
      def build_checkbox_attributes
        attrs = @html_options.except(:class, :id, :checked, :include_hidden)
        attrs[:type] = 'checkbox'
        attrs[:class] = checkbox_classes
        attrs[:checked] = 'checked' if @checked
        attrs
      end

      # Renders the hidden field for unchecked value.
      #
      # This method expects the including class to have TagHelper available
      #
      # @param name [String] the field name
      # @param value [String] the unchecked value
      # @return [ActiveSupport::SafeBuffer] the hidden field HTML
      def render_hidden_field(name, value)
        tag.input(type: 'hidden', name: name, value: value)
      end
    end
  end
end
