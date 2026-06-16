# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for comparison-based search conditions (>, <, >=, <=)
    module ComparisonOperators
      extend ActiveSupport::Concern

      # Suffix convention for date-type metadata fields
      # TODO: still necessary?
      # DATE_FIELD_SUFFIX = '_date'

      private

      # TODO: still necessary?
      # def date_metadata_field?(metadata_key)
      #   metadata_key.end_with?(DATE_FIELD_SUFFIX)
      # end

      def metadata_condition_date_comparison(scope, node, value, comparison_method)
        scope
          .where(node.matches_regexp('^\\d{4}(-\\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).public_send(comparison_method, value)
          )
      end

      def metadata_condition_numeric_comparison(scope, node, value, comparison_method)
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
