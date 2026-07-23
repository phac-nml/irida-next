# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for comparison-based search conditions (>, <, >=, <=, numeric_less_than_equals,
    # numeric_greater_than_equals, date_less_than_equals, date_greater_than_equals)
    module ComparisonOperators
      extend ActiveSupport::Concern

      private

      def condition_less_than_or_equal(scope, node, value, metadata_key)
        return scope.where(node.lteq(value)) unless metadata_key

        perform_metadata_comparison(scope, node, value, :lteq, metadata_key)
      end

      def condition_greater_than_or_equal(scope, node, value, metadata_key)
        return scope.where(node.gteq(value)) unless metadata_key

        perform_metadata_comparison(scope, node, value, :gteq, metadata_key)
      end
    end
  end
end
