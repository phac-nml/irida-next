# frozen_string_literal: true

module Flowbite
  # File: base_button.rb
  # Purpose: Defines the BaseButton class for the Flowbite component library
  #
  # This file contains the implementation of the BaseButton class, which serves as
  # a foundation for creating button components in the Flowbite framework. It
  # provides functionality for customizing button attributes such as tag, type,
  # appearance, and disabled state.
  #
  # The BaseButton class is part of the Flowbite module and inherits from
  # Flowbite::Component, allowing it to integrate seamlessly with other Flowbite
  # components.
  class BaseButton < Flowbite::Component
    # Define constants for default and allowed values
    DEFAULT_TAG = :button
    TAG_OPTIONS = [DEFAULT_TAG, :a].freeze

    DEFAULT_TYPE = :button
    TYPE_OPTIONS = [DEFAULT_TYPE, :submit, :reset].freeze

    attr_reader :disabled
    alias disabled? disabled

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
    def call
      render(Flowbite::BaseComponent.new(**@system_arguments)) { content }
    end
  end
end
