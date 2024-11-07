# frozen_string_literal: true

module Pathogen
  # This module contains methods for generating and managing button sizes.
  module ButtonSizes
    # Default size for buttons
    DEFAULT_SIZE = :medium

    # A hash of predefined button size mappings
    SIZE_MAPPINGS = {
      small: 'px-3 py-2 text-xs',
      medium: 'px-3 py-2 text-sm'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys
  end
end
