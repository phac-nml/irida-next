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

      def condition_between(scope, node, value)
        if valid_date_format?(value[0]) && valid_date_format?(value[1])
          condition_date_between(scope, node, value)
        elsif valid_numeric_format?(value[0]) && valid_numeric_format?(value[1])
          condition_numeric_between(scope, node, value)
        else
          condition_text_between(scope, node, value)
        end
      end

      def condition_numeric_between(scope, node, value)
        casted_node = Arel::Nodes::NamedFunction.new(
          'CAST',
          [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
        )

        scope.where(node.matches_regexp('^-?\\d+(\\.\\d+)?$').and(
                      casted_node.between(value[0].to_f..value[1].to_f)
                    ))
      end

      def condition_date_between(scope, node, value)
        casted_node = Arel::Nodes::NamedFunction.new(
          'TO_DATE',
          [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
        )

        scope.where(node.matches_regexp('^\\d{4}-\\d{2}-\\d{2}$').and(
                      casted_node.between(value[0]..value[1])
                    ))
      end

      def condition_text_between(scope, node, value)
        lower_node = Arel::Nodes::NamedFunction.new('LOWER', [node])

        scope.where(lower_node.between(
                      value[0].downcase..value[1].downcase
                    ))
      end
    end
  end
end
