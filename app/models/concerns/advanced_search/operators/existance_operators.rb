# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for pattern matching search conditions (CONTAINS, NOT CONTAINS, EXISTS)
    module ExistenceOperators
      extend ActiveSupport::Concern

      private

      def condition_exists(scope, node)
        scope.where(node.not_eq(nil))
      end

      def condition_not_exists(scope, node)
        scope.where(node.eq(nil))
      end
    end
  end
end
