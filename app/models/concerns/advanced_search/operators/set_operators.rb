# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for set-based search conditions (IN, NOT IN)
    module SetOperators
      extend ActiveSupport::Concern

      private

      def condition_in(scope, node, value, metadata_field:, field_name:)
        # Enum metadata fields need exact matching, not case-insensitive matching
        is_enum_metadata = AdvancedSearch::Operators::ENUM_METADATA_FIELDS.include?(field_name)

        # Use case-insensitive matching only for non-enum metadata fields
        if metadata_field && !is_enum_metadata
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).in(downcase_values(value)))
        elsif field_name == 'name'
          scope.where(node.lower.in(downcase_values(value)))
        else
          # Exact matching for enum metadata fields and regular fields
          scope.where(node.in(value.compact))
        end
      end

      def condition_not_in(scope, node, value, metadata_field:, field_name:)
        # Enum metadata fields need exact matching, not case-insensitive matching
        is_enum_metadata = AdvancedSearch::Operators::ENUM_METADATA_FIELDS.include?(field_name)

        # Use case-insensitive matching only for non-enum metadata fields
        if metadata_field && !is_enum_metadata
          condition_not_in_metadata(scope, node, value)
        elsif field_name == 'name'
          scope.where(node.lower.not_in(downcase_values(value)))
        else
          # Exact matching for enum metadata fields and regular fields
          scope.where(node.not_in(value.compact))
        end
      end

      def condition_not_in_metadata(scope, node, value)
        lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])
        scope.where(node.eq(nil).or(lower_function.not_in(downcase_values(value))))
      end

      def downcase_values(value)
        value.compact.map { |v| v.to_s.downcase }
      end
    end
  end
end
