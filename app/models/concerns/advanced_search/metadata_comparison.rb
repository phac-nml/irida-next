# frozen_string_literal: true

# Shared filtering logic for metadata specific advanced search.

module AdvancedSearch
  # Includes search methods specific to metadata (comparison and set operations)
  module MetadataComparison
    extend ActiveSupport::Concern

    # Suffix convention for date-type metadata fields
    DATE_FIELD_SUFFIX = '_date'

    private

    # metadata comparison
    def perform_metadata_comparison(scope, node, value, comparison_method, metadata_key)
      if date_metadata_field?(metadata_key)
        metadata_condition_date_comparison(scope, node, value, comparison_method)
      else
        metadata_condition_numeric_comparison(scope, node, value, comparison_method)
      end
    end

    def date_metadata_field?(metadata_key)
      metadata_key.end_with?(DATE_FIELD_SUFFIX)
    end

    def metadata_condition_date_comparison(scope, node, value, comparison_method)
      return scope.none unless valid_date_format?(value)

      scope
        .where(node.matches_regexp('^\\d{4}(-\\d{2}){0,2}$'))
        .where(
          Arel::Nodes::NamedFunction.new(
            'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
          ).public_send(comparison_method, value)
        )
    end

    # handles all numeric comparisons (:eq, :not_eq, :gteq, :lteq)
    def metadata_condition_numeric_comparison(scope, node, value, comparison_method)
      return scope.none unless valid_numeric_format?(value)

      scope
        .where(node.matches_regexp('^-?\\d+(\\.\\d+)?$'))
        .where(Arel::Nodes::NamedFunction.new(
          'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
        ).public_send(comparison_method, value.to_f))
    end

    def valid_date_format?(value)
      Date.iso8601(value.to_s)
      true
    rescue ArgumentError
      false
    end

    def valid_numeric_format?(value)
      value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    end

    # set operations
    def condition_in_metadata(scope, node, value)
      scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).in(downcase_values(value)))
    end

    def condition_not_in_metadata(scope, node, value)
      lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])
      # Include NULL metadata values in negative set operations: NULL is not in the provided set.
      # This maintains consistency with condition_not_equals, where "not X" includes records without the field.
      scope.where(node.eq(nil).or(lower_function.not_in(downcase_values(value))))
    end
  end
end
