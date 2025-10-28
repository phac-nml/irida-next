# frozen_string_literal: true

module Pathogen
  # Pathogen::Icon renders icons using rails_icons with variant coloring and system arguments.
  #
  # This component provides a clean, modern interface to rails_icons while adding Pathogen's
  # styling system on top. It handles icon name normalization, applies consistent color and
  # size theming, and provides proper error handling with accessibility defaults.
  #
  # The component is built using a modular architecture with separate classes handling:
  # - IconValidator: Parameter validation and normalization
  # - IconRenderer: HTML generation and cleanup
  # - IconErrorHandler: Error handling and fallbacks
  #
  # @example Basic icon usage
  #   = render Pathogen::Icon.new(:clipboard_text)
  #   = render Pathogen::Icon.new(:arrow_up)
  #
  # @example With Pathogen styling options
  #   = render Pathogen::Icon.new(:clipboard_text, color: :primary, size: :lg)
  #   = render Pathogen::Icon.new(:heart, color: :danger, size: :sm)
  #   = render Pathogen::Icon.new(:heart, color: nil, class: "text-purple-500")
  #
  # @example With rails_icons options
  #   = render Pathogen::Icon.new(:heart, variant: :fill, library: :heroicons)
  #   = render Pathogen::Icon.new(:check, class: "w-6 h-6 text-green-500")
  #
  # @example With accessibility options
  #   = render Pathogen::Icon.new(:info, "aria-hidden": false, "aria-label": "Information")
  #
  class Icon < Pathogen::Component
    attr_reader :icon_name, :color, :size, :variant, :rails_icons_options

    # Initialize a new Icon component
    #
    # @param icon_name [String, Symbol] The icon name (e.g., "clipboard-text", :arrow_up)
    # @param color [Symbol, nil] Pathogen color variant (:default, :primary, :success, etc.)
    #   or nil to skip color classes
    # @param size [Symbol] Pathogen size variant (:sm, :md, :lg, :xl)
    # @param variant [String, Symbol] rails_icons variant (e.g., :fill, :outline)
    # @param library [String, Symbol] rails_icons library (e.g., :heroicons, :phosphor)
    # @param options [Hash] Additional system arguments passed to rails_icons
    def initialize(icon_name, color: :default, size: :md, variant: nil, library: nil, **options) # rubocop:disable Metrics/ParameterLists
      @icon_name = IconValidator.normalize_icon_name(icon_name)
      @color = IconValidator.validate_color(color)
      @size = IconValidator.validate_size(size)
      @variant = variant

      @rails_icons_options = build_rails_icons_options(variant, library, options)
      apply_pathogen_styling
    end

    # Render the icon using rails_icons with proper error handling
    #
    # @return [ActiveSupport::SafeBuffer, nil] The rendered icon HTML or error fallback
    def call
      html = helpers.icon(icon_name, **rails_icons_options)
      IconRenderer.clean_html(html)
    rescue StandardError => e
      error_handler.handle_error(e)
    end

    private

    # Build the complete options hash for rails_icons
    #
    # @param variant [String, Symbol, nil] Icon variant
    # @param library [String, Symbol, nil] Icon library
    # @param additional_options [Hash] Additional options to merge
    # @return [Hash] Complete options hash for rails_icons
    def build_rails_icons_options(variant, library, additional_options)
      IconRenderer.build_options(variant, library, additional_options)
    end

    # Apply Pathogen color and size styling to the icon options
    def apply_pathogen_styling
      IconRenderer.apply_styling(rails_icons_options, color, size, variant)
      IconRenderer.append_icon_name_class(rails_icons_options, icon_name) unless Rails.env.production?
    end

    # Get the error handler instance for this icon
    #
    # @return [IconErrorHandler] The error handler instance
    def error_handler
      @error_handler ||= IconErrorHandler.new(icon_name, rails_icons_options)
    end
  end
end
