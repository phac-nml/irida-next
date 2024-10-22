# frozen_string_literal: true

module Flowbite
  # This module contains methods for generating and managing button sizes.
  module ButtonSizes
    # Default size for buttons
    DEFAULT_SIZE = :default

    # A hash of predefined button size mappings
    SIZE_MAPPINGS = {
      extra_small: 'px-3 py-2 text-xs',
      small: 'px-3 py-2 text-sm',
      default: 'px-5 py-2.5 text-sm',
      large: 'px-5 py-3 text-base',
      extra_large: 'px-6 py-3.5 text-base'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys
  end
end
