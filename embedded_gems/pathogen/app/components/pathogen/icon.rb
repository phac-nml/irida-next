# frozen_string_literal: true

module Pathogen
  # Pathogen::Icon renders icons using rails_icons with variant coloring and system arguments.
  #
  # This component provides a clean, modern interface to rails_icons while adding Pathogen's
  # styling system on top. It handles icon name normalization, applies consistent color and
  # size theming, and provides proper error handling with accessibility defaults.
  #
  # @example Basic icon usage
  #   = render Pathogen::Icon.new("clipboard-text")
  #   = render Pathogen::Icon.new(:arrow_up)
  #
  # @example With Pathogen styling options
  #   = render Pathogen::Icon.new("clipboard-text", color: :primary, size: :lg)
  #   = render Pathogen::Icon.new("heart", color: :danger, size: :sm)
  #
  # @example With rails_icons options
  #   = render Pathogen::Icon.new("heart", variant: :fill, library: :heroicons)
  #   = render Pathogen::Icon.new("check", class: "w-6 h-6 text-green-500")
  #
  # @example With accessibility options
  #   = render Pathogen::Icon.new("info", "aria-hidden": false, "aria-label": "Information")
  #
  class Icon < Pathogen::Component
    # Tailwind color variants for icon text color
    COLORS = {
      default: 'text-slate-900 dark:text-slate-100',
      subdued: 'text-slate-600 dark:text-slate-300',
      primary: 'text-primary-600 dark:text-primary-500',
      success: 'text-green-600 dark:text-green-500',
      warning: 'text-yellow-600 dark:text-yellow-500',
      danger: 'text-red-600 dark:text-red-500',
      blue: 'text-blue-600 dark:text-blue-500'
    }.freeze

    SIZES = {
      sm: 'size-4',
      md: 'size-6',
      lg: 'size-8',
      xl: 'size-10'
    }.freeze

    # Initialize a new Icon component
    #
    # @param icon_name [String, Symbol] The icon name (e.g., "clipboard-text", :arrow_up)
    # @param color [Symbol] Pathogen color variant (:default, :primary, :success, etc.)
    # @param size [Symbol] Pathogen size variant (:sm, :md, :lg, :xl)
    # @param variant [String, Symbol] rails_icons variant (e.g., :fill, :outline)
    # @param library [String, Symbol] rails_icons library (e.g., :heroicons, :phosphor)
    # @param options [Hash] Additional system arguments passed to rails_icons
    def initialize(icon_name, color: :default, size: :md, variant: nil, library: nil, **options)
      @icon_name = normalize_icon_name(icon_name)

      # Build rails_icons options with variant and library
      @rails_icons_options = build_rails_icons_options(variant, library, options)

      # Apply Pathogen styling classes
      apply_pathogen_styling(color, size)

      # Ensure aria-hidden is set for decorative icons unless explicitly provided
      ensure_accessibility_defaults
    end

    # Render the icon using rails_icons
    #
    # @return [ActiveSupport::SafeBuffer, nil] The rendered icon HTML or error fallback
    def call
      icon(@icon_name, **@rails_icons_options)
    rescue StandardError => e
      handle_icon_error(e)
    end

    private

    # Normalize icon name to string format expected by rails_icons
    #
    # @param name [String, Symbol] The icon name to normalize
    # @return [String] Normalized icon name
    def normalize_icon_name(name)
      return name.to_s if name.is_a?(String)

      # Convert symbols like :arrow_up to "arrow-up" for rails_icons compatibility
      name.to_s.tr('_', '-')
    end

    # Build the options hash for rails_icons with variant, library, and additional options
    #
    # @param variant [String, Symbol, nil] Icon variant
    # @param library [String, Symbol, nil] Icon library
    # @param additional_options [Hash] Additional options to merge
    # @return [Hash] Complete options hash for rails_icons
    def build_rails_icons_options(variant, library, additional_options)
      options = additional_options.dup

      # Add rails_icons specific options
      options[:variant] = variant if variant
      options[:library] = library if library

      # Add icon-specific class for development debugging (non-production only)
      add_debug_class(options) unless Rails.env.production?

      options
    end

    # Apply Pathogen color and size styling to the icon
    #
    # @param color [Symbol] Color variant
    # @param size [Symbol] Size variant
    def apply_pathogen_styling(color, size)
      pathogen_classes = class_names(
        COLORS[color] => COLORS.key?(color),
        SIZES[size] => SIZES.key?(size)
      )

      @rails_icons_options[:class] = class_names(
        pathogen_classes,
        @rails_icons_options[:class]
      )
    end

    # Ensure proper accessibility defaults for decorative icons
    def ensure_accessibility_defaults
      # Set aria-hidden=true by default unless explicitly provided
      unless @rails_icons_options.key?('aria-hidden') || @rails_icons_options.key?(:'aria-hidden')
        @rails_icons_options['aria-hidden'] = true
      end
    end

    # Add debug class for development environments
    #
    # @param options [Hash] Options hash to modify
    def add_debug_class(options)
      debug_class = "#{@icon_name}-icon"
      existing_class = options[:class] || options['class'] || ''
      options[:class] = "#{existing_class} #{debug_class}".strip
    end

    # Handle icon rendering errors with appropriate fallbacks
    #
    # @param error [StandardError] The error that occurred
    # @return [ActiveSupport::SafeBuffer, nil] Error fallback HTML or nil
    def handle_icon_error(error)
      Rails.logger.warn "[Pathogen::Icon] Failed to render icon '#{@icon_name}': #{error.message}"

      # Return helpful error indicator in local environments
      if Rails.env.local?
        content_tag(:span, "⚠️ Icon '#{@icon_name}' not found",
                    class: 'text-red-500 text-xs font-mono',
                    title: "Icon rendering error: #{error.message}")
      end
    end
  end
end
