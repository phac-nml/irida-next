# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for set-based search conditions (IN, NOT IN)
    module SetOperators
      extend ActiveSupport::Concern

      private

      def condition_in(scope, node, value, metadata_field:, field_name:)
        # Use case-insensitive matching for metadata fields (both enum and non-enum)
        if metadata_field
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).in(downcase_values(value)))
        elsif field_name == 'name'
          scope.where(node.lower.in(downcase_values(value)))
        else
          # Exact matching for regular fields
          scope.where(node.in(compact_values(value)))
        end
      end

      def condition_not_in(scope, node, value, metadata_field:, field_name:)
        # Use case-insensitive matching for metadata fields (both enum and non-enum)
        if metadata_field
          condition_not_in_metadata(scope, node, value)
        elsif field_name == 'name'
          scope.where(node.lower.not_in(downcase_values(value)))
        else
          # Exact matching for regular fields
          scope.where(node.not_in(compact_values(value)))
        end
      end

      def condition_not_in_metadata(scope, node, value)
        lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])
        # Include NULL metadata values in negative set operations: NULL is not in the provided set.
        # This maintains consistency with condition_not_equals, where "not X" includes records without the field.
        scope.where(node.eq(nil).or(lower_function.not_in(downcase_values(value))))
      end

      def downcase_values(value)
        compact_values(value).map { |v| v.to_s.downcase }
      end

      def compact_values(value)
        Array(value).compact
      end
    end
  end
end
