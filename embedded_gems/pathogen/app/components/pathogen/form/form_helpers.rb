# frozen_string_literal: true

# 🟢 Pathogen::Form::FormHelpers 🟢
#
# 🎯 Purpose:
#   This module provides common form helper methods that can be used across form components.
#   It handles input naming, ID generation, and ARIA attributes consistently.
#
# 🚀 Usage Example:
#   module Pathogen
#     module Form
#       class MyFormComponent < ViewComponent::Base
#         include FormHelpers
#
#         def initialize(form: nil, attribute:, **options)
#           @form = form
#           @attribute = attribute
#           extract_options!(options)
#         end
#       end
#     end
#   end
#
# 🧩 Features:
#   - Consistent input naming and ID generation
#   - ARIA attribute handling
#   - Help text ID generation
#   - Form attribute extraction
#
# ♿ Accessibility:
#   - Proper ARIA attribute handling
#   - Consistent ID generation for labels and descriptions
#   - Support for help text and error messages

module Pathogen
  module Form
    # Generic form helper methods that can be used across form components
    module FormHelpers
      # Generates a unique ID for help text elements
      # @return [String] The help text ID
      def help_text_id
        @help_text_id ||= "#{input_id}_help"
      end

      # Generates the input name based on form builder or direct attribute
      # @return [String] The input name
      def input_name
        return @input_name if @input_name.present?
        return "#{@form.object_name}[#{@attribute}]" if @form

        @attribute.to_s
      end

      # Generates a unique ID for the input element
      # @return [String] The input ID
      def input_id
        base = if @form
                 "#{@form.object_name}_#{@attribute}_#{@value}"
               else
                 "#{input_name}_#{@value}"
               end
        base.gsub(/[\[\]]+/, '_').chomp('_')
      end

      # Generates form attributes including ARIA and classes
      # @param user_class [String, nil] Additional classes to merge
      # @return [Hash] Form attributes hash
      def form_attributes
        describedby = [
          @described_by,
          (@help_text.present? ? help_text_id : nil)
        ].compact.join(' ')

        {
          disabled: @disabled,
          class: input_classes(@user_class),
          aria: aria_attributes.merge(describedby: describedby.presence),
          tabindex: @disabled ? -1 : 0,
          onchange: @onchange
        }.compact
      end

      # Generates ARIA attributes for accessibility
      # @return [Hash] ARIA attributes hash
      def aria_attributes
        {
          disabled: @disabled.to_s,
          describedby: @described_by,
          controls: @controls
        }.compact
      end

      # Extracts and assigns options to instance variables
      # @param options [Hash] Options to extract
      def extract_options!(options)
        @options = options.dup
        @input_name = options.delete(:input_name)
        @label = options.delete(:label)
        @checked = options.delete(:checked) { false }
        @disabled = options.delete(:disabled) { false }
        @described_by = options.delete(:described_by)
        @controls = options.delete(:controls)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @help_text = options.delete(:help_text)
        @user_class = options.delete(:class)
        @html_options = options # Remaining options (e.g., data-*)
      end
    end
  end
end
