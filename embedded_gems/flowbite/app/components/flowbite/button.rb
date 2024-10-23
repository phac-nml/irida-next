# frozen_string_literal: true

module Flowbite
  # This file defines the Flowbite::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Flowbite
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Flowbite::Component
    include Flowbite::ButtonSchemes
    include Flowbite::ButtonVisuals
    include Flowbite::ButtonSizes

    DEFAULT_CLASSES = 'rounded-lg font-medium focus:outline-none focus:ring-4 ' \
                      'disabled:opacity-50 disabled:cursor-not-allowed'

    # rubocop:disable Metrics/ParameterLists
    def initialize(base_button_class: Flowbite::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   disabled: false, label_wrap: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @label_wrap = label_wrap
      @size = size
      @block = block

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)],
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
  end
end
