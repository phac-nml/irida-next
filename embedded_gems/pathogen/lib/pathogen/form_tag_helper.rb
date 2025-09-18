# frozen_string_literal: true

require_relative 'styles/form_styles'
require_relative 'test_selector_helper'

module Pathogen
  # Module that overrides Rails form tag helpers to provide Pathogen styling
  module FormTagHelper
    extend ActiveSupport::Concern
    include Pathogen::Styles::FormStyles
    include Pathogen::TestSelectorHelper

    included do
      # Override check_box_tag to use Pathogen styling
      # Follows the exact Rails signature: check_box_tag(name, value = "1", checked = false, options = {})
      def check_box_tag(name, value = '1', checked = false, options = {}) # rubocop:disable Style/OptionalBooleanParameter
        # Apply Pathogen styling to checkbox options
        options = apply_pathogen_styling(options)
        options = add_test_selector(options)
        options = options.except(:include_hidden) if options.key?(:include_hidden)

        # Call the default Rails check_box_tag with our enhanced options
        super
      end
    end
  end
end
