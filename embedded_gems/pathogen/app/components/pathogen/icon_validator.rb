# frozen_string_literal: true

module Pathogen
  # IconValidator handles parameter validation and normalization for Pathogen::Icon.
  #
  # This class encapsulates all validation logic for icon parameters including
  # color, size, and icon name validation with appropriate fallbacks and warnings.
  class IconValidator
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

    class << self
      # Validate and return a valid color or fallback to default
      #
      # @param color [Symbol] The color to validate
      # @return [Symbol] Valid color or :default fallback
      def validate_color(color)
        return color if COLORS.key?(color)

        Rails.logger.warn "[Pathogen::Icon] Invalid color '#{color}', " \
                          "falling back to :default. Valid colors: #{COLORS.keys.join(', ')}"
        :default
      end

      # Validate and return a valid size or fallback to medium
      #
      # @param size [Symbol] The size to validate
      # @return [Symbol] Valid size or :md fallback
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
      # @raise [ArgumentError] If name is nil or blank
      def normalize_icon_name(name)
        raise ArgumentError, 'Icon name cannot be nil or blank' if name.blank?

        normalized = name.is_a?(String) ? name : name.to_s.tr('_', '-')

        validate_icon_name_format(normalized)
        normalized.downcase
      end

      private

      # Validate icon name format and log warnings for suspicious names
      #
      # @param normalized [String] The normalized icon name
      def validate_icon_name_format(normalized)
        return unless normalized.length > 50 || normalized.match?(/[^a-z0-9\-_]/)

        Rails.logger.warn "[Pathogen::Icon] Suspicious icon name: '#{normalized}'"
      end
    end
  end
end
