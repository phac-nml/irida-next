# frozen_string_literal: true

module Flowbite
  # This module contains methods for generating and managing button schemes.
  module ButtonSchemes
    # Default color scheme for buttons
    DEFAULT_SCHEME = :light

    # Generates a CSS class string for a button scheme
    #
    # @param color [String] The base color name
    # @param text_color [String] The text color
    # @param bg_shade [String, Integer] The background shade
    # @param focus_shade [String, Integer] The focus ring shade
    # @param dark_bg_shade [String, Integer] The background shade for dark mode
    # @param border [Boolean] Whether to include a border (default: false)
    # @return [String] A space-separated string of CSS classes
    # rubocop:disable Metrics/ParameterLists
    def self.generate_scheme(color, text_color, bg_shade, focus_shade, dark_bg_shade, border: false)
      classes = [
        "text-#{text_color}",
        "bg-#{color}-#{bg_shade}",
        "focus:ring-#{color}-#{focus_shade}",
        "dark:bg-#{color}-#{dark_bg_shade}",
        "dark:focus:ring-#{color}-#{focus_shade}",
        "enabled:hover:bg-#{color}-#{bg_shade.to_i + 100}",
        "dark:enabled:hover:bg-#{color}-#{dark_bg_shade.to_i - 100}"
      ]

      classes << "border border-#{color}-#{bg_shade}" if border
      classes << "dark:border-#{color}-600" if border

      classes.join(' ')
    end

    # rubocop:enable Metrics/ParameterLists

    # Generates a hash of button scheme mappings
    #
    # @return [Hash] A frozen hash of button scheme mappings
    def self.generate_scheme_mappings
      {
        primary: generate_scheme('primary', 'slate-50', '700', '300', '800'),
        blue: generate_scheme('blue', 'white', '700', '300', '600'),
        alternative: generate_scheme('gray', 'gray-900', 'white', '100', '800', border: true),
        dark: generate_scheme('slate', 'white', '700', '300', '700'),
        light: generate_scheme('slate', 'slate-900', 'white', '100', '800', border: true),
        green: generate_scheme('green', 'white', '600', '300', '500'),
        red: generate_scheme('red', 'white', '600', '300', '500'),
        yellow: generate_scheme('yellow', 'slate-900', '300', '300', '300'),
        purple: generate_scheme('purple', 'white', '600', '300', '500')
      }.freeze
    end

    # A hash of predefined button scheme mappings
    SCHEME_MAPPINGS = generate_scheme_mappings

    # An array of available button scheme options
    SCHEME_OPTIONS = SCHEME_MAPPINGS.keys
  end
end
