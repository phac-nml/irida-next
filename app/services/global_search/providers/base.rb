# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Base behavior shared by all global search providers.
    class Base < BaseService
      include Rails.application.routes.url_helpers

      SCORE_BUCKET_EXACT_IDENTIFIER = 1
      SCORE_BUCKET_EXACT_NAME = 2
      SCORE_BUCKET_PREFIX = 3
      SCORE_BUCKET_METADATA_KEY = 4
      SCORE_BUCKET_METADATA_VALUE = 5
      SCORE_BUCKET_FUZZY = 6

      private

      def build_result(**attributes)
        GlobalSearch::Result.new(**attributes)
      end

      def apply_created_filters(scope, created_from:, created_to:)
        scope = scope.where(created_at: created_from..) if created_from
        scope = scope.where(created_at: ..created_to) if created_to
        scope
      end

      def ilike_pattern(query)
        "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      end

      def prefix_pattern(query)
        "#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      end

      def search_binds(query:)
        {
          exact: query,
          pattern: ilike_pattern(query)
        }
      end

      def exact_match?(value, query)
        return false if value.blank? || query.blank?

        value.to_s.casecmp?(query)
      end

      def exact_on_any?(values, query)
        values.any? { |value| exact_match?(value, query) }
      end

      def prefix_match?(value, query)
        return false if value.blank? || query.blank?

        value.to_s.downcase.start_with?(query.downcase)
      end

      def prefix_on_any?(values, query)
        values.any? { |value| prefix_match?(value, query) }
      end

      def contains_match?(value, query)
        return false if value.blank? || query.blank?

        value.to_s.downcase.include?(query.downcase)
      end
    end
  end
end
