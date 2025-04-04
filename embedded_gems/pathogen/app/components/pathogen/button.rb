# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Pathogen
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Pathogen::Component
    include Pathogen::ButtonSizes
    include Pathogen::ButtonVisuals

    SCHEME_OPTIONS = %i[primary default danger].freeze
    DEFAULT_SCHEME = :default
    DEFAULT_CLASSES = 'relative cursor-pointer font-medium text-center items-center ' \
                      'inline-flex gap-2 select-none rounded ' \
                      'disabled:opacity-70 disabled:cursor-not-allowed transition ease-in ' \
                      'active:transition-none border border-1'

    def initialize(base_button_class: Pathogen::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block

      @system_arguments = system_arguments

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:class],
        DEFAULT_CLASSES,
        generate_scheme_mapping(fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)),
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        'block w-full' => block
      )
    end

    private

    # Trims the content by removing leading and trailing whitespace.
    # If the content is blank, returns nil.
    # If the content is marked as HTML safe, ensures the trimmed content remains HTML safe.
    #
    # @return [String, nil] The trimmed content, or nil if the content is blank.
    def trimmed_content
      return if content.blank?

      trimmed_content = content.strip

      return trimmed_content unless content.html_safe?

      # strip unsets `html_safe`, so we have to set it back again to guarantee that HTML blocks won't break
      trimmed_content.html_safe # rubocop:disable Rails/OutputSafety
    end

    # Generates the appropriate CSS classes for the button's color scheme and tag type.
    #
    # @param scheme [Symbol] The color scheme of the button (:primary, :default, or :danger).
    # @return [String] A string of CSS classes corresponding to the specified scheme.
    def generate_scheme_mapping(scheme)
      # rubocop:disable Layout/LineLength
      {
        primary: 'bg-primary-700 text-white enabled:hover:bg-primary-800',
        default: 'text-slate-900 bg-white border-slate-200 hover:bg-slate-100 disabled:hover:bg-white ' \
                 'dark:text-slate-100 dark:bg-slate-800 dark:border-slate-600 dark:hover:text-white dark:hover:bg-slate-800 dark:enabled:hover:text-red-100',
        danger: 'bg-slate-50 text-red-500 enabled:hover:text-red-50 dark:enabled:hover:text-red-50 enabled:hover:bg-red-800 dark:text-red-500 '
      }[scheme]
      # rubocop:enable Layout/LineLength
    end
  end
end
