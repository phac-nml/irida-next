# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for between-based search conditions (between, date_between, numeric_between, text_between)
    module BetweenOperators
      extend ActiveSupport::Concern

      private

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

      # date and metadata date values (eg: datetime vs YYYY-MM-DD metadata string) need to be handled slightly
      # differently. metadata_date_between in metadata_comparison.rb
      def condition_date_between(scope, node, value)
        casted_node = Arel::Nodes::NamedFunction.new(
          'DATE',
          [node]
        )

        scope.where(casted_node.between(value[0]..value[1]))
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
