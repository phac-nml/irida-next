# frozen_string_literal: true

module Pathogen
  module Typography
    # Shared functionality for typography components
    # Provides variant validation and color class generation
    module Shared
      VARIANT_OPTIONS = %i[default muted subdued inverse].freeze
      DEFAULT_VARIANT = :default

      private

      def color_classes_for_variant(variant)
        Constants::COLOR_VARIANTS[
          fetch_or_fallback(VARIANT_OPTIONS, variant, DEFAULT_VARIANT)
        ]
      end
    end
  end
end
