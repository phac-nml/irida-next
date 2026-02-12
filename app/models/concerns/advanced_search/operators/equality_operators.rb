# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for equality-based search conditions
    module EqualityOperators
      extend ActiveSupport::Concern

      private

      def condition_equals(scope, node, value, metadata_field:, field_name:)
        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !enum_metadata_field?(field_name)

        if use_pattern_match
          scope.where(node.matches(value))
        elsif metadata_field && enum_metadata_field?(field_name)
          # Case-insensitive exact match for enum metadata fields
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).eq(value.downcase))
        else
          # Exact match for regular fields
          scope.where(node.eq(value))
        end
      end

      def condition_not_equals(scope, node, value, metadata_field:, field_name:)
        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !enum_metadata_field?(field_name)

        if use_pattern_match
          # Include NULL records - user searching for "not X" expects records without this field
          scope.where(node.eq(nil).or(node.does_not_match(value)))
        elsif metadata_field && enum_metadata_field?(field_name)
          # Case-insensitive not-equals for enum metadata fields
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).not_eq(value.downcase))
        else
          # Exact matching for regular fields
          scope.where(node.not_eq(value))
        end
      end
    end
  end
end
