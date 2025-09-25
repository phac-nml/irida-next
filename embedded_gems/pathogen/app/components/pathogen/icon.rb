# frozen_string_literal: true

module Pathogen
  # Pathogen::Icon renders icons using rails_icons with variant coloring and system arguments.
  #
  # @example Direct icon name usage
  #   = render Pathogen::Icon.new("clipboard-text")
  #   = render Pathogen::Icon.new(:arrow_up)
  #
  # @example With pathogen styling options
  #   = render Pathogen::Icon.new("clipboard-text", color: :primary, size: :lg)
  #
  # @example With rails_icons options
  #   = render Pathogen::Icon.new("heart", variant: :fill, library: :heroicons)
  #   = render Pathogen::Icon.new("check", class: "w-6 h-6 text-green-500")
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

    # @param icon_name [Symbol, String] The icon name (e.g., "clipboard-text", :arrow_up)
    # @param options [Hash] Options including color, size, variant, library, and system arguments
    def initialize(icon_name_or_hash, **options)
      # Handle both new API (direct names) and legacy ICON hash constants
      if icon_name_or_hash.is_a?(Hash) && icon_name_or_hash[:name]
        # Legacy ICON constant format
        @icon_name = normalize_icon_name(icon_name_or_hash[:name])
        legacy_options = icon_name_or_hash[:options] || {}
        merged_options = legacy_options.merge(options)
      else
        # New direct name format
        @icon_name = normalize_icon_name(icon_name_or_hash)
        merged_options = options
      end

      # Extract pathogen and rails_icons options
      color = merged_options.delete(:color) || :default
      size = merged_options.delete(:size) || :md
      variant = merged_options.delete(:variant)
      library = merged_options.delete(:library)

      # Build rails_icons options
      @rails_icons_options = build_rails_icons_options(variant, library)

      # Build final class with pathogen styling + user classes
      pathogen_classes = class_names(
        COLORS[color] => color.present?,
        SIZES[size] => size.present?
      )

      @rails_icons_options[:class] = class_names(
        pathogen_classes,
        merged_options[:class]
      )

      # Merge remaining system arguments (excluding class to avoid duplication)
      remaining_options = merged_options.except(:class)
      @rails_icons_options.merge!(remaining_options)
    end

    # Render the icon using rails_icons (via render_icon for backward compatibility)
    def call
      render_icon(@icon_name, **@rails_icons_options)
    rescue StandardError => e
      Rails.logger.warn "[Pathogen::Icon] Failed to render icon '#{@icon_name}': #{e.message}"

      # Return helpful error in development/test
      if Rails.env.local?
        content_tag :span, "⚠️ Icon '#{@icon_name}' not found",
                    class: 'text-red-500 text-xs font-mono'
      end
    end

    private

    # Normalize icon name to string format expected by rails_icons
    def normalize_icon_name(name)
      return name.to_s if name.is_a?(String)

      # Convert symbols like :arrow_up to "arrow-up"
      name.to_s.tr('_', '-')
    end

    # Extract rails_icons specific options
    def build_rails_icons_options(variant, library)
      options = {}
      options[:variant] = variant if variant
      options[:library] = library if library
      options
    end
  end
end
