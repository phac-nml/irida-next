# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for equality-based search conditions
    module EqualityOperators
      extend ActiveSupport::Concern

      private

      def condition_equals(scope, node, value, field_name:)
        # Use pattern matching only for non-enum metadata fields and name field
        if field_name == 'name'
          equals_pattern_match(scope, node, value)
        else
          # Exact match for regular fields
          equals(scope, node, value)
        end
      end

      def metadata_condition_equals(scope, node, value, field_name:)
        if enum_metadata_field?(field_name)
          # Case-insensitive exact match for enum metadata fields
          normalized_value = normalize_case_insensitive_value(value)
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).eq(normalized_value))
        else
          # TODO: possibly need to match ints with floats and vice versa
          equals_pattern_match(scope, node, value)
        end
      end

      def condition_not_equals(scope, node, value, field_name:)
        # Use pattern matching only for non-enum metadata fields and name field
        if field_name == 'name'
          # Include NULL records - user searching for "not X" expects records without this field
          not_equals_pattern_match(scope, node, value)
        else
          # Exact matching for regular fields
          scope.where(node.not_eq(value))
        end
      end

      def metadata_condition_not_equals(scope, node, value, field_name:)
        # Use pattern matching only for non-enum metadata fields and name field

        if enum_metadata_field?(field_name)
          # Case-insensitive not-equals for enum metadata fields
          normalized_value = normalize_case_insensitive_value(value)
          lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])

          # Include NULL metadata values for consistency with other negative operators.
          scope.where(node.eq(nil).or(lower_function.not_eq(normalized_value)))
        else
          # Exact matching for regular fields
          not_equals_pattern_match(scope, node, value)
        end
      end

      def equals_pattern_match(scope, node, value)
        scope.where(node.matches(value))
      end

      def equals(scope, node, value)
        scope.where(node.eq(value))
      end

      def not_equals_pattern_match(scope, node, value)
        scope.where(node.eq(nil).or(node.does_not_match(value)))
      end

      def normalize_case_insensitive_value(value)
        value.to_s.downcase
      end
    end
  end
end
