# frozen_string_literal: true

module Pathogen
  # Module that overrides Rails form tag helpers to provide Pathogen styling
  module FormTagHelper
    extend ActiveSupport::Concern

    included do
      # Override check_box_tag to use Pathogen styling
      def check_box_tag(name, value = '1', checked: false, options: {})
        # Handle both old and new calling patterns
        # If checked is a Hash, it means the old code is calling with options as 3rd param
        if checked.is_a?(Hash)
          options = checked
          checked = false
        end

        # For check_box_tag, we need to adjust options to include checked state
        adjusted_options = options.dup
        adjusted_options[:checked] = checked

        # Render using Pathogen component with standalone signature
        # object_name, method, options, checked_value, unchecked_value
        Pathogen::Form::Checkbox.new(name, value, adjusted_options, '1', '0').call
      end
    end
  end
end
