# frozen_string_literal: true

module Flowbite
  # :nodoc:
  module FetchOrFallbackHelper
    def fetch_or_fallback(allowed_values, given_value, fallback = nil, deprecated_values: nil)
      return given_value if allowed_values.include?(given_value)

      if deprecated_values&.include?(given_value)
        warn_deprecation(given_value) unless Rails.env.production? || silence_deprecations?
        return given_value
      end

      handle_invalid_value(allowed_values, given_value, fallback)
    end

    private

    def warn_deprecation(given_value)
      ::Flowbite::ViewComponents.deprecation.warn(
        "#{given_value} is deprecated and will be removed in a future version."
      )
    end

    def handle_invalid_value(allowed_values, given_value, fallback)
      if fallback_raises && ENV['RAILS_ENV'] != 'production'
        raise InvalidValueError, <<~MSG
          fetch_or_fallback was called with an invalid value.

          Expected one of: #{allowed_values.inspect}
          Got: #{given_value.inspect}

          This will not raise in production, but will instead fallback to: #{fallback.inspect}
        MSG
      end

      fallback
    end
  end
end
