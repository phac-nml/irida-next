# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for equality-based search conditions
    module EqualityOperators
      extend ActiveSupport::Concern

      private

      def condition_equals(scope, node, value, field_name)
        metadata_field = metadata_field?(field_name)
        return condition_date_equals(scope, node, value) if standard_date_field?(field_name)

        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !enum_metadata_field?(field_name)

        if use_pattern_match
          scope.where(node.matches(value))
        elsif metadata_field && enum_metadata_field?(field_name)
          # Case-insensitive exact match for enum metadata fields
          normalized_value = normalize_case_insensitive_value(value)
          scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).eq(normalized_value))
        else
          # Exact match for regular fields
          scope.where(node.eq(value))
        end
      end

      def condition_not_equals(scope, node, value, field_name)
        metadata_field = metadata_field?(field_name)
        return condition_date_not_equals(scope, node, value) if standard_date_field?(field_name)

        # Use pattern matching only for non-enum metadata fields and name field
        use_pattern_match = (metadata_field || field_name == 'name') && !enum_metadata_field?(field_name)

        return condition_pattern_not_equals(scope, node, value) if use_pattern_match
        return condition_enum_not_equals(scope, node, value) if metadata_field && enum_metadata_field?(field_name)

        # Exact matching for regular fields
        scope.where(node.not_eq(value))
      end

      def normalize_case_insensitive_value(value)
        value.to_s.downcase
      end

      def standard_date_field?(field_name)
        !metadata_field?(field_name) && field_name.end_with?('_at')
      end

      def condition_date_equals(scope, node, value)
        start_time = date_start(value)
        scope.where(node.gteq(start_time).and(node.lt(start_time + 1.day)))
      end

      def condition_date_not_equals(scope, node, value)
        start_time = date_start(value)
        scope.where(node.lt(start_time).or(node.gteq(start_time + 1.day)))
      end

      def condition_pattern_not_equals(scope, node, value)
        # Include NULL records - user searching for "not X" expects records without this field.
        scope.where(node.eq(nil).or(node.does_not_match(value)))
      end

      def condition_enum_not_equals(scope, node, value)
        normalized_value = normalize_case_insensitive_value(value)
        lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])

        # Include NULL metadata values for consistency with other negative operators.
        scope.where(node.eq(nil).or(lower_function.not_eq(normalized_value)))
      end

      def date_start(value)
        Date.iso8601(value.to_s).in_time_zone.beginning_of_day
      end
    end
  end
end
