# frozen_string_literal: true

module Flowbite
  # This file defines the Flowbite::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Flowbite
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Flowbite::Component
    include Flowbite::ButtonVisuals
    include Flowbite::ButtonSizes

    SCHEME_OPTIONS = %i[primary default danger].freeze
    DEFAULT_SCHEME = :default
    # rubocop:disable Layout/LineLength
    DEFAULT_CLASSES = 'rounded-lg font-medium focus:outline-none focus:ring-4 focus:z-10 disabled:opacity-70 disabled:cursor-not-allowed'
    # rubocop:enable Layout/LineLength

    # rubocop:disable Metrics/ParameterLists
    def initialize(base_button_class: Flowbite::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   disabled: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
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
      enabled_prefix = enableable? ? 'enabled:' : ''
      # rubocop:disable Layout/LineLength
      case scheme
      when :primary
        "bg-primary-700 text-white #{enabled_prefix}hover:bg-primary-800 focus:ring-primary-300 dark:focus:ring-primary-600"
      when :default
        "text-slate-900 bg-white border border-slate-200 #{enabled_prefix}hover:bg-slate-100 #{enabled_prefix}hover:text-primary-700 focus:ring-4 focus:ring-slate-100 dark:focus:ring-slate-700 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-600 #{enabled_prefix}dark:hover:text-white #{enabled_prefix}dark:hover:bg-slate-700"
      when :danger
        "border border-red-100 bg-slate-50 text-red-500 #{enabled_prefix}hover:text-red-50 #{enabled_prefix}dark:hover:text-red-50 #{enabled_prefix}hover:bg-red-800 focus:ring-red-300 dark:border-red-800 dark:bg-slate-900 dark:text-red-500 dark:focus:ring-red-900"
      end
      # rubocop:enable Layout/LineLength
    end

    def enableable?
      @system_arguments[:tag].present? && @system_arguments[:tag] == 'a'
    end
  end
end
