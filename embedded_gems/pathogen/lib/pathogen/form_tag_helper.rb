# frozen_string_literal: true

module Pathogen
  # Module that overrides Rails form tag helpers to provide Pathogen styling
  module FormTagHelper
    extend ActiveSupport::Concern

    included do
      # Override check_box_tag to use Pathogen styling
      # Follows the exact Rails signature: check_box_tag(name, value = "1", checked = false, options = {})
      def check_box_tag(name, value = '1', checked = false, options = {}) # rubocop:disable Style/OptionalBooleanParameter
        # Render using the Pathogen CheckBoxTag component for standalone fields
        Pathogen::Form::CheckBoxTag.new(name, value, checked, options).call
      end
    end
  end
end
