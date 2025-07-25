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
    # rubocop:disable Layout/LineLength
    DEFAULT_CLASSES = 'relative cursor-pointer select-none transition ease-in-out delay-150 duration-300 rounded-lg font-medium focus:z-10 disabled:opacity-70 disabled:cursor-not-allowed'
    # rubocop:enable Layout/LineLength

    # rubocop:disable Metrics/ParameterLists
    def initialize(base_button_class: Pathogen::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   disabled: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:class],
        generate_scheme_mapping(fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)),
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        DEFAULT_CLASSES,
        'block w-full' => block
      )
    end

    # rubocop:enable Metrics/ParameterLists

    def before_render
      return unless leading_visual.present? || trailing_visual.present?

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'text-center inline-flex items-center'
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
        default: 'text-slate-900 bg-white border border-slate-200 enabled:hover:bg-slate-100 enabled:hover:text-primary-700 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-600 dark:enabled:hover:text-white dark:enabled:hover:bg-slate-700',
        danger: 'border border-red-100 bg-slate-50 text-red-500 enabled:hover:text-red-50 dark:enabled:hover:text-red-50 enabled:hover:bg-red-800 dark:border-red-800 dark:bg-slate-900 dark:text-red-500'
      }[scheme]
      # rubocop:enable Layout/LineLength
    end
  end
end
