# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for comparison-based search conditions (>, <, >=, <=)
    module ComparisonOperators
      extend ActiveSupport::Concern

      private

      def condition_less_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
        return scope.where(node.lteq(value)) unless metadata_field

        if metadata_key.end_with?('_date')
          condition_date_comparison(scope, node, value, :lteq)
        else
          condition_numeric_comparison(scope, node, value, :lteq)
        end
      end

      def condition_greater_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
        return scope.where(node.gteq(value)) unless metadata_field

        if metadata_key.end_with?('_date')
          condition_date_comparison(scope, node, value, :gteq)
        else
          condition_numeric_comparison(scope, node, value, :gteq)
        end
      end

      def condition_date_comparison(scope, node, value, comparison_method)
        scope
          .where(node.matches_regexp('^\\d{4}(-\\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).public_send(comparison_method, value)
          )
      end

      def condition_numeric_comparison(scope, node, value, comparison_method)
        scope
          .where(node.matches_regexp('^-?\\d+(\\.\\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).public_send(comparison_method, value)
          )
      end
    end
  end
end
