# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for set-based search conditions (in, not_in, text_in, text_not_in)
    module SetOperators
      extend ActiveSupport::Concern

      private

      def condition_in(scope, node, value, field_name:)
        # Use case-insensitive matching for metadata fields (both enum and non-enum)
        if metadata_field?(field_name)
          condition_in_metadata(scope, node, value)
        elsif field_name == 'name'
          scope.where(node.lower.in(downcase_values(value)))
        else
          # Exact matching for regular fields
          scope.where(node.in(compact_values(value)))
        end
      end

      def condition_not_in(scope, node, value, field_name:)
        # Use case-insensitive matching for metadata fields (both enum and non-enum)
        if metadata_field?(field_name)
          condition_not_in_metadata(scope, node, value)
        elsif field_name == 'name'
          scope.where(node.lower.not_in(downcase_values(value)))
        else
          # Exact matching for regular fields
          scope.where(node.not_in(compact_values(value)))
        end
      end

      def downcase_values(value)
        compact_values(value).map { |v| v.to_s.downcase }
      end

      def compact_values(value)
        Array(value).compact_blank
      end
    end
  end
end
