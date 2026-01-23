# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for equality-based search conditions
    module EqualityOperators
      extend ActiveSupport::Concern

      private

      def condition_equals(scope, node, value, metadata_field:, field_name:)
        if metadata_field || field_name == 'name'
          scope.where(node.matches(value))
        else
          scope.where(node.eq(value))
        end
      end

      def condition_not_equals(scope, node, value, metadata_field:, field_name:)
        if metadata_field || field_name == 'name'
          scope.where(node.eq(nil).or(node.does_not_match(value)))
        else
          scope.where(node.not_eq(value))
        end
      end
    end
  end
end
