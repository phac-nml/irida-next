# frozen_string_literal: true

module AdvancedSearch
  module V2
    module Tree
      # Immutable value object representing a single filter condition in a V2 query tree.
      class ConditionNode
        attr_reader :field, :operator, :value

        def initialize(field:, operator:, value:)
          @field = field
          @operator = operator
          @value = value
        end

        def type = :condition
      end
    end
  end
end
