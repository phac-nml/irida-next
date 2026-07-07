# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for existence search conditions (exists, not_exists)
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
