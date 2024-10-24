# frozen_string_literal: true

module Pathogen
  # This file defines the BaseButton class within the Pathogen module.
  # BaseButton is a foundational component for creating buttons in the Pathogen design system.
  #
  class BaseButton < Pathogen::Component
    # Define constants for default and allowed values
    DEFAULT_TAG = :button
    TAG_OPTIONS = [DEFAULT_TAG, :a].freeze

    DEFAULT_TYPE = :button
    TYPE_OPTIONS = [DEFAULT_TYPE, :submit, :reset].freeze

    attr_reader :disabled
    alias disabled? disabled

    # Initialize a new BaseButton instance
    # @param tag [Symbol] The HTML tag to use for the button (:button or :a)
    # @param type [Symbol] The type attribute for button tags (:button, :submit, or :reset)
    # @param disabled [Boolean] Whether the button should be disabled
    # @param system_arguments [Hash] Additional arguments to be passed to the component
    def initialize(tag: DEFAULT_TAG, type: DEFAULT_TYPE, disabled: false, **system_arguments)
      @system_arguments = system_arguments

      # Set the tag and type
      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, DEFAULT_TAG)
      if @system_arguments[:tag] == :button
        @system_arguments[:type] =
          fetch_or_fallback(TYPE_OPTIONS, type, DEFAULT_TYPE)
      end

      # Handle disabled state
      @disabled = disabled
      return unless @disabled

      # Convert disabled anchors to buttons since a tags cannot be disabled
      @system_arguments[:tag] = :button
      @system_arguments[:disabled] = true
    end

    # Render the button using the BaseComponent
    # @return [Pathogen::BaseComponent] The rendered button component
    def call
      render(Pathogen::BaseComponent.new(**@system_arguments)) { content }
    end
  end
end
