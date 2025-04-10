# frozen_string_literal: true

module Pathogen
  # Base component class that provides core functionality for rendering HTML tags
  # @private
  # :nocov:
  class BaseComponent < Pathogen::Component
    SELF_CLOSING_TAGS = %i[area base br col embed hr img input link meta param source track
                           wbr].freeze

    # Initialize a new component with the given tag and options
    #
    # @param tag [Symbol, String] the HTML tag to render
    # @param classes [String, Array, nil] CSS classes to apply to the component
    # @param system_arguments [Hash] additional HTML attributes to apply
    # @raise [ArgumentError] if tag is not valid
    def initialize(tag:, classes: nil, **system_arguments)
      @tag = tag.to_sym
      validate_tag(@tag)
      @system_arguments = system_arguments || {}

      @result = {
        class: class_names(classes, @system_arguments[:class]),
        style: @system_arguments[:style]
      }.compact

      @system_arguments[:'data-view-component'] = true

      # Add a test selector for easier component testing
      @content_tag_args = add_test_selector(@system_arguments)
    end

    # Renders the component as HTML
    #
    # @return [ActiveSupport::SafeBuffer] rendered HTML
    def call
      if self_closing_tag?(@tag)
        tag(@tag, @content_tag_args.merge(@result))
      else
        content_tag(@tag, content, @content_tag_args.merge(@result))
      end
    end

    private

    # Check if the given tag is self-closing
    #
    # @param tag [Symbol] the tag to check
    # @return [Boolean] whether the tag is self-closing
    def self_closing_tag?(tag)
      SELF_CLOSING_TAGS.include?(tag)
    end

    # Validate that the tag is allowed
    #
    # @param tag [Symbol] the tag to validate
    # @raise [ArgumentError] if the tag is not valid
    def validate_tag(tag)
      return if tag.is_a?(Symbol)

      raise ArgumentError, "Expected tag to be a Symbol, got #{tag.class}"
    end
  end
end
