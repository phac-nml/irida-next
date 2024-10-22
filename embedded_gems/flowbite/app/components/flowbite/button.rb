# frozen_string_literal: true

module Flowbite
  # This file defines the Flowbite::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Flowbite
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Flowbite::Component
    DEFAULT_SCHEME = :light
    SCHEME_MAPPINGS = {
      primary: 'text-slate-50 bg-primary-700 focus:ring-primary-300 dark:bg-primary-800 dark:bg-primary-700 dark:focus:ring-primary-800 enabled:hover:bg-primary-800 enabled:dark:hover:bg-primary-700',
      blue: 'text-white bg-blue-700 focus:ring-blue-300 dark:bg-blue-600 dark:focus:ring-blue-800 enabled:hover:bg-blue-800 enabled:dark:hover:bg-blue-700',
      alternative: 'text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 enabled:hover:bg-gray-100 enabled:hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700',
      dark: 'text-white bg-slate-700 focus:ring-slate-300 dark:bg-slate-700 dark:focus:ring-slate-700 dark:border-slate-700 enabled:hover:bg-slate-800 enabled:dark:hover:bg-slate-600',
      light: 'text-slate-900 bg-white border border-slate-300 focus:outline-none enabled:hover:bg-slate-100 focus:ring-4 focus:ring-slate-100 dark:bg-slate-800 dark:text-white dark:border-slate-600 dark:hover:bg-slate-700 dark:hover:border-slate-600 dark:focus:ring-slate-700',
      green: 'text-white bg-green-600 focus:ring-green-300 dark:bg-green-500 dark:focus:ring-green-800 enabled:hover:bg-green-700 enabled:dark:hover:bg-green-600 disabled:opacity-50',
      red: 'text-white bg-red-600 focus:ring-red-300 dark:bg-red-500 dark:focus:ring-red-900 enabled:hover:bg-red-700 enabled:dark:hover:bg-red-600 disabled:opacity-50',
      yellow: 'text-slate-900 bg-yellow-300 focus:ring-yellow-300 dark:focus:ring-yellow-900 enabled:hover:bg-yellow-400 enabled:dark:hover:bg-yellow-500 disabled:bg-yellow-200 disabled:text-slate-500',
      purple: 'text-white bg-purple-600 focus:ring-purple-300 dark:bg-purple-500 dark:focus:ring-purple-900 enabled:hover:bg-purple-700 enabled:dark:hover:bg-purple-600'
    }.freeze
    SCHEME_OPTIONS = SCHEME_MAPPINGS.keys

    DEFAULT_SIZE = :default
    SIZE_MAPPINGS = {
      extra_small: 'px-3 py-2 text-xs',
      small: 'px-3 py-2 text-sm',
      default: 'px-5 py-2.5 text-sm',
      large: 'px-5 py-3 text-base',
      extra_large: 'px-6 py-3.5 text-base'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys

    DEFAULT_ALIGN_CONTENT = :center
    ALIGN_CONTENT_MAPPINGS = {
      :start => 'Button-content--alignStart',
      :center => '',
      DEFAULT_ALIGN_CONTENT => ''
    }.freeze
    ALIGN_CONTENT_OPTIONS = ALIGN_CONTENT_MAPPINGS.keys

    def initialize(base_button_class: Flowbite::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE,
                   align_content: DEFAULT_ALIGN_CONTENT, disabled: false, label_wrap: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @label_wrap = label_wrap

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)],
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        'rounded-lg font-medium focus:outline-none focus:ring-4 disabled:opacity-50 disabled:cursor-not-allowed'
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
  end
end
