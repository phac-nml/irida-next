# frozen_string_literal: true

module Pathogen
  # Base button component for the Pathogen design system.
  # Provides a foundation for creating accessible, styled buttons with consistent behavior.
  #
  # @example Basic usage
  #   <%= render Pathogen::BaseButton.new(type: :submit) { "Click me" } %>
  #
  # @example Disabled link button
  #   <%= render Pathogen::BaseButton.new(
  #     tag: :a,
  #     href: "#",
  #     disabled: true
  #   ) { "Disabled Link" } %>
  class BaseButton < Pathogen::Component
    # Default and allowed values configuration
    module Configuration
      DEFAULT_TAG = :button
      TAG_OPTIONS = [DEFAULT_TAG, :a].freeze

      DEFAULT_TYPE = :button
      TYPE_OPTIONS = [DEFAULT_TYPE, :submit, :reset].freeze
    end
    private_constant :Configuration

    include Configuration

    # @!attribute [r] disabled
    #   @return [Boolean] whether the button is disabled
    attr_reader :disabled
    alias disabled? disabled

    # Initialize a new BaseButton instance.
    #
    # @param tag [Symbol] the HTML tag to use (:button or :a)
    # @param type [Symbol] the type attribute for button tags (:button, :submit, or :reset)
    # @param disabled [Boolean] whether the button should be disabled
    # @param system_arguments [Hash] additional HTML attributes for the button
    # @option system_arguments [String] :href required when tag is :a
    # @raise [ArgumentError] if invalid tag or type is provided
    def initialize(tag: Configuration::DEFAULT_TAG, type: Configuration::DEFAULT_TYPE, disabled: false,
                   **system_arguments)
      @system_arguments = system_arguments
      @disabled = disabled

      validate_arguments!(tag, type)
      set_tag_and_type(tag, type)
      handle_disabled_state

      # Set default classes if none provided
      @system_arguments[:classes] = default_classes(@system_arguments[:classes])
    end

    # @return [Pathogen::BaseComponent] the rendered button component
    def call
      render(Pathogen::BaseComponent.new(**@system_arguments)) { content }
    end

    private

    def validate_arguments!(tag, type)
      return if Configuration::TAG_OPTIONS.include?(tag) &&
                (tag != :button || Configuration::TYPE_OPTIONS.include?(type))

      raise ArgumentError, "Invalid tag: #{tag.inspect} or type: #{type.inspect}"
    end

    def set_tag_and_type(tag, type)
      @system_arguments[:tag] = fetch_or_fallback(Configuration::TAG_OPTIONS, tag, Configuration::DEFAULT_TAG)

      return unless @system_arguments[:tag] == :button

      @system_arguments[:type] = fetch_or_fallback(Configuration::TYPE_OPTIONS, type, Configuration::DEFAULT_TYPE)
    end

    def handle_disabled_state
      return unless disabled?

      # Convert disabled anchors to buttons since a tags cannot be disabled
      @system_arguments[:tag] = :button
      @system_arguments[:aria_disabled] = true
      @system_arguments[:disabled] = true
      @system_arguments[:tabindex] = -1
    end

    def default_classes(custom_classes)
      base_classes = %w[
        rounded-lg inline-flex min-h-11 min-w-11 cursor-pointer items-center
        justify-center border px-5 py-2.5 text-sm font-semibold transition
        duration-200 disabled:cursor-not-allowed disabled:opacity-80 sm:w-auto
      ]

      if custom_classes.present?
        "#{base_classes.join(' ')} #{custom_classes}"
      else
        base_classes.join(' ')
      end
    end
  end
end
