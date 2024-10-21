# frozen_string_literal: true

module Flowbite
  class Button < Flowbite::Component
    DEFAULT_SCHEME = :default
    SCHEME_MAPPINGS = {
      primary: 'text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800',
      secondary: 'Button--secondary',
      default: 'text-gray-900 focus:outline-none bg-white border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700',
      danger: 'Button--danger',
      invisible: 'Button--invisible',
      link: 'Button--link'
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

    def initialize(base_button_class: Flowbite::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   align_content: DEFAULT_ALIGN_CONTENT, disabled: false, label_wrap: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @block = block
      @label_wrap = label_wrap

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)],
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        'rounded-lg font-medium'
      )
    end

    private

    def trimmed_content
      return if content.blank?

      trimmed_content = content.strip

      return trimmed_content unless content.html_safe?

      # strip unsets `html_safe`, so we have to set it back again to guarantee that HTML blocks won't break
      trimmed_content.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
