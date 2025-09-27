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
    def initialize(icon_name, color: :default, size: :md, variant: nil, library: nil, **options) # rubocop:disable Metrics/ParameterLists
      @icon_name = normalize_icon_name(icon_name)

      # Validate and normalize parameters
      @color = validate_color(color)
      @size = validate_size(size)

      # Store variant for styling decisions
      @variant = variant

      # Build rails_icons options with variant and library
      @rails_icons_options = build_rails_icons_options(variant, library, options)

      # Apply Pathogen styling classes
      apply_pathogen_styling
    end

    # Render the icon using rails_icons
    #
    # @return [ActiveSupport::SafeBuffer, nil] The rendered icon HTML or error fallback
    def call
      html = icon(@icon_name, **@rails_icons_options)
      # Remove any data attributes from the final HTML as they're not allowed on SVG
      remove_data_attributes_from_html(html)
    rescue StandardError => e
      handle_icon_error(e)
    end

    private

    # Validate color parameter and provide fallback
    #
    # @param color [Symbol] The color to validate
    # @return [Symbol] Valid color or fallback
    def validate_color(color)
      return color if COLORS.key?(color)

      Rails.logger.warn "[Pathogen::Icon] Invalid color '#{color}', " \
                        "falling back to :default. Valid colors: #{COLORS.keys.join(', ')}"
      :default
    end

    # Validate size parameter and provide fallback
    #
    # @param size [Symbol] The size to validate
    # @return [Symbol] Valid size or fallback
    def validate_size(size)
      return size if SIZES.key?(size)

      Rails.logger.warn "[Pathogen::Icon] Invalid size '#{size}', " \
                        "falling back to :md. Valid sizes: #{SIZES.keys.join(', ')}"
      :md
    end

    # Normalize icon name to string format expected by rails_icons
    #
    # @param name [String, Symbol] The icon name to normalize
    # @return [String] Normalized icon name
    def normalize_icon_name(name)
      raise ArgumentError, 'Icon name cannot be nil or blank' if name.blank?

      normalized = name.is_a?(String) ? name : name.to_s.tr('_', '-')

      # Add basic validation for reasonable icon names
      if normalized.length > 50 || normalized.match?(/[^a-z0-9\-_]/)
        Rails.logger.warn "[Pathogen::Icon] Suspicious icon name: '#{normalized}'"
      end

      normalized.downcase
    end

    # Build the options hash for rails_icons with variant, library, and additional options
    #
    # @param variant [String, Symbol, nil] Icon variant
    # @param library [String, Symbol, nil] Icon library
    # @param additional_options [Hash] Additional options to merge
    # @return [Hash] Complete options hash for rails_icons
    def build_rails_icons_options(variant, library, additional_options)
      options = additional_options.dup

      # Remove data attributes as they're not allowed on SVG elements
      filter_data_attributes(options)

      # Add rails_icons specific options
      options[:variant] = variant if variant
      options[:library] = library if library

      # Add icon-specific class for development debugging (non-production only)
      add_debug_class(options) unless Rails.env.production?

      options
    end

    # Apply Pathogen color and size styling to the icon
    def apply_pathogen_styling
      @rails_icons_options[:class] = class_names(
        pathogen_classes,
        @rails_icons_options[:class]
      )
    end

    # Memoized pathogen styling classes for performance
    def pathogen_classes
      @pathogen_classes ||= class_names(
        COLORS[@color],
        SIZES[@size],
        filled_variant_class
      )
    end

    # Add CSS class for filled variants to ensure they inherit color
    def filled_variant_class
      return 'fill-current' if @variant&.to_s == 'fill'

      nil
    end

    # Remove data attributes from options since they're not allowed on SVG elements
    #
    # @param options [Hash] Options hash to filter
    def filter_data_attributes(options)
      # Remove any keys that start with 'data-' or are exactly 'data'
      keys_to_remove = options.keys.select do |key|
        key_str = key.to_s
        key_str.start_with?('data-') || key_str == 'data'
      end

      keys_to_remove.each { |key| options.delete(key) }

      # Debug logging in development
      return unless Rails.env.development? && keys_to_remove.any?

      Rails.logger.debug { "[Pathogen::Icon] Removed data attributes: #{keys_to_remove.inspect} from #{@icon_name}" }
    end

    # Remove data attributes from rendered HTML using regex
    #
    # @param html [String] The HTML string to clean
    # @return [ActiveSupport::SafeBuffer] Cleaned HTML
    def remove_data_attributes_from_html(html)
      return html unless html.is_a?(String)

      # Remove data attributes from SVG elements
      cleaned_html = html.gsub(/\s+data(?:-[a-z0-9-]*)?(?:="[^"]*")?/i, '')
      cleaned_html.html_safe
    end

    # Add debug class for development environments
    #
    # @param options [Hash] Options hash to modify
    def add_debug_class(options)
      existing_class = options[:class] || options['class'] || ''
      options[:class] = "#{existing_class} #{debug_class}".strip
    end

    # Memoized debug class for performance
    def debug_class
      @debug_class ||= "#{@icon_name}-icon"
    end

    # Handle icon rendering errors with appropriate fallbacks
    #
    # @param error [StandardError] The error that occurred
    # @return [ActiveSupport::SafeBuffer, nil] Error fallback HTML or nil
    def handle_icon_error(error)
      # Log with more context
      Rails.logger.warn "[Pathogen::Icon] Failed to render icon '#{@icon_name}' " \
                        "with options #{@rails_icons_options.inspect}: " \
                        "#{error.message}"

      # Try fallback strategies
      fallback_icon = attempt_fallback_icon
      return fallback_icon if fallback_icon

      # Return development error indicator
      return development_error_indicator(error) if Rails.env.local?

      # Return nothing in production to avoid breaking layouts
      nil
    end

    # Attempt to render fallback icons when primary icon fails
    #
    # @return [ActiveSupport::SafeBuffer, nil] Fallback icon HTML or nil
    def attempt_fallback_icon
      fallbacks = %w[question-mark-circle warning]

      fallbacks.each do |fallback_name|
        return icon(fallback_name, **@rails_icons_options.except(:variant, :library))
      rescue StandardError
        next
      end

      nil
    end

    # Create enhanced development error indicator with suggestions
    #
    # @param error [StandardError] The original error
    # @return [ActiveSupport::SafeBuffer] Error indicator HTML
    def development_error_indicator(error)
      suggestions = suggest_similar_icons
      suggestion_text = suggestions.any? ? " (Suggestions: #{suggestions.join(', ')})" : ''

      content_tag(:span, "⚠️ Icon '#{@icon_name}' not found#{suggestion_text}",
                  class: 'text-red-500 text-xs font-mono border border-red-300 ' \
                         'rounded px-2 py-1 bg-red-50',
                  title: "Icon rendering error: #{error.message}")
    end

    # Suggest similar icon names based on common patterns
    #
    # @return [Array<String>] Array of suggested icon names
    def suggest_similar_icons
      suggestions = {
        /check/ => %w[check check-circle check-badge],
        /arrow/ => %w[arrow-up arrow-down arrow-left arrow-right],
        /user/ => %w[user user-circle users],
        /plus/ => %w[plus plus-circle plus-square],
        /minus/ => %w[minus minus-circle minus-square],
        /x/ => %w[x x-circle x-mark],
        /eye/ => %w[eye eye-slash],
        /heart/ => %w[heart heart-fill]
      }

      suggestions.find { |pattern, _| @icon_name.match?(pattern) }&.last || []
    end
  end
end
