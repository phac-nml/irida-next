# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for equality-based search conditions
    module EqualityOperators
      extend ActiveSupport::Concern

      private

      def condition_equals(scope, node, value, metadata_field:, field_name:)
        # Enum metadata fields need exact matching, not pattern matching
        is_enum_metadata = AdvancedSearch::Operators::ENUM_METADATA_FIELDS.include?(field_name)

        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !is_enum_metadata

        if use_pattern_match
          scope.where(node.matches(value))
        else
          scope.where(node.eq(value))
        end
      end

      def condition_not_equals(scope, node, value, metadata_field:, field_name:)
        # Enum metadata fields need exact matching, not pattern matching
        is_enum_metadata = AdvancedSearch::Operators::ENUM_METADATA_FIELDS.include?(field_name)

        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !is_enum_metadata

        if use_pattern_match
          scope.where(node.eq(nil).or(node.does_not_match(value)))
        else
          scope.where(node.not_eq(value))
        end
      end
    end
  end
end
