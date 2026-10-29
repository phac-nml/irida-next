# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for comparison-based search conditions (>, <, >=, <=, numeric_less_than_equals,
    # numeric_greater_than_equals, date_less_than_equals, date_greater_than_equals)
    module ComparisonOperators
      extend ActiveSupport::Concern

      private

      def condition_less_than_or_equal(scope, node, value, metadata_key, field_name = nil)
        if standard_date_comparison?(metadata_key, field_name)
          return condition_date_less_than_or_equal(scope, node, value)
        end
        return scope.where(node.lteq(value)) unless metadata_key

        perform_metadata_comparison(scope, node, value, :lteq, metadata_key)
      end

      def condition_greater_than_or_equal(scope, node, value, metadata_key, field_name = nil)
        if standard_date_comparison?(metadata_key, field_name)
          return condition_date_greater_than_or_equal(scope, node, value)
        end
        return scope.where(node.gteq(value)) unless metadata_key

        perform_metadata_comparison(scope, node, value, :gteq, metadata_key)
      end

      def standard_date_comparison?(metadata_key, field_name)
        !metadata_key && field_name.present? && standard_date_field?(field_name)
      end

      # Inclusive of the whole end day: value <= end-of-day, expressed as < start of next day.
      def condition_date_less_than_or_equal(scope, node, value)
        scope.where(node.lt(date_start(value) + 1.day))
      end

      def condition_date_greater_than_or_equal(scope, node, value)
        scope.where(node.gteq(date_start(value)))
      end
    end
  end
end
