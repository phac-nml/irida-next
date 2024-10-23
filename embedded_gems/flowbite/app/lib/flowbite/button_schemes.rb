# frozen_string_literal: true

module Flowbite
  # This module contains methods for generating and managing button schemes.
  module ButtonSchemes
    # Default color scheme for buttons
    DEFAULT_SCHEME = :default

    # rubocop:disable Layout/LineLength
    DEFAULT_CLASSES = 'rounded-lg font-medium focus:outline-none focus:ring-4 focus:z-10 disabled:opacity-70 disabled:cursor-not-allowed'

    # Generates a hash of button scheme mappings
    #
    # @return [Hash] A frozen hash of button scheme mappings
    def self.generate_scheme_mappings
      {
        primary: "#{DEFAULT_CLASSES} bg-primary-700 text-white enabled:hover:bg-primary-800 focus:ring-primary-300 dark:focus:ring-primary-600",
        default: "#{DEFAULT_CLASSES} text-slate-900 bg-white border border-slate-200 enabled:hover:bg-slate-100 enabled:hover:text-primary-700 focus:ring-4 focus:ring-slate-100 dark:focus:ring-slate-700 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-600 enabled:dark:hover:text-white enabled:dark:hover:bg-slate-700",
        danger: "#{DEFAULT_CLASSES} border border-red-100 bg-slate-50 text-red-500 enabled:hover:text-red-50 enabled:dark:hover:text-red-50 enabled:hover:bg-red-800 focus:ring-red-300 dark:border-red-800 dark:bg-slate-900 dark:text-red-500 dark:focus:ring-red-900"
      }.freeze
    end
    # rubocop:enable Layout/LineLength

    # A hash of predefined button scheme mappings
    SCHEME_MAPPINGS = generate_scheme_mappings

    # An array of available button scheme options
    SCHEME_OPTIONS = SCHEME_MAPPINGS.keys
  end
end
