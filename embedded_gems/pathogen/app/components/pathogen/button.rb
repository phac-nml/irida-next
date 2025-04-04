# frozen_string_literal: true

module Pathogen
  # 🔘 Button Component
  #
  # A highly customizable button component that provides consistent styling and behavior
  # across your application. Built with accessibility and flexibility in mind.
  #
  # Features:
  # - 🎨 Multiple color schemes (primary, default, danger)
  # - 📏 Various sizes (xs, sm, base, lg, xl)
  # - 🔧 Configurable width (inline or full-width)
  # - ♿ Accessible by default
  # - 🌙 Dark mode support
  #
  # @example Basic usage
  #   = render(Pathogen::Button.new(scheme: :primary)) { "Click me" }
  #
  # @example With custom styling
  #   = render(Pathogen::Button.new(
  #       scheme: :danger,
  #       size: :lg,
  #       block: true,
  #       class: "my-custom-class"
  #     )) { "Delete" }
  #
  # @example Disabled state
  #   = render(Pathogen::Button.new(
  #       scheme: :primary,
  #       disabled: true
  #     )) { "Processing..." }
  class Button < Pathogen::Component
    include Pathogen::ButtonVisuals
    include Pathogen::ButtonStyles

    # 🎨 Style configuration inherited from ButtonStyles
    SCHEME_OPTIONS = Pathogen::ButtonStyles::SCHEME_OPTIONS
    DEFAULT_SCHEME = Pathogen::ButtonStyles::DEFAULT_SCHEME
    SIZE_OPTIONS = Pathogen::ButtonStyles::SIZE_OPTIONS
    DEFAULT_SIZE = Pathogen::ButtonStyles::DEFAULT_SIZE

    # 🏗️ Initializes a new button component
    #
    # @param base_button_class [Class] The base button class to extend from (default: Pathogen::BaseButton)
    # @param scheme [Symbol] Color scheme for the button (:primary, :default, :danger)
    # @param size [Symbol] Button size (:xs, :sm, :base, :lg, :xl)
    # @param block [Boolean] Whether the button should be full width
    # @param system_arguments [Hash] Additional HTML attributes (class, disabled, etc.)
    # @option system_arguments [String] :id HTML ID attribute
    # @option system_arguments [String] :class Additional CSS classes
    # @option system_arguments [Boolean] :disabled Whether the button is disabled
    def initialize(
      base_button_class: Pathogen::BaseButton,
      scheme: DEFAULT_SCHEME,
      size: DEFAULT_SIZE,
      block: false,
      **system_arguments
    )
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block
      @system_arguments = system_arguments
      @id = @system_arguments[:id]

      apply_button_styles
    end

    private

    # 🎨 Applies the button's visual styles based on configuration
    def apply_button_styles
      @system_arguments[:classes] = generate_classes(
        scheme: fetch_or_fallback(SCHEME_OPTIONS, @scheme, DEFAULT_SCHEME),
        size: fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE),
        block: @block,
        disabled: @system_arguments[:disabled],
        custom_classes: @system_arguments[:class]
      )
    end

    # ✂️ Processes and sanitizes the button content
    #
    # Handles content trimming and HTML safety while preserving
    # the original HTML safety status of the content.
    #
    # @return [String, nil] Processed content or nil if blank
    def trimmed_content
      return if content.blank?

      trimmed = content.strip
      return trimmed unless content.html_safe?

      # Preserve HTML safety after string manipulation
      trimmed.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
