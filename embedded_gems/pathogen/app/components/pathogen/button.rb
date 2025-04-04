# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Pathogen
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Pathogen::Component
    include Pathogen::ButtonVisuals
    include Pathogen::ButtonStyles

    SCHEME_OPTIONS = Pathogen::ButtonStyles::SCHEME_OPTIONS
    DEFAULT_SCHEME = Pathogen::ButtonStyles::DEFAULT_SCHEME
    SIZE_OPTIONS = Pathogen::ButtonStyles::SIZE_OPTIONS
    DEFAULT_SIZE = Pathogen::ButtonStyles::DEFAULT_SIZE

    # @param base_button_class [Class] The base button class to use
    # @param scheme [Symbol] The color scheme for the button
    # @param size [Symbol] The size of the button
    # @param block [Boolean] Whether the button should be full width
    # @param system_arguments [Hash] Additional HTML attributes
    def initialize(base_button_class: Pathogen::BaseButton, scheme: :base, size: DEFAULT_SIZE, block: false,
                   **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block

      @system_arguments = system_arguments

      @id = @system_arguments[:id]

      @system_arguments[:classes] = generate_classes(
        scheme: fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME),
        size: fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE),
        block: block,
        disabled: @system_arguments[:disabled],
        custom_classes: system_arguments[:class]
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
