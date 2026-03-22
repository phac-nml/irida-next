# frozen_string_literal: true

module AdvancedSearch
  module V2
    module Tree
      # Immutable value object representing a single filter condition in a V2 query tree.
      class ConditionNode
        attr_reader :field, :operator, :value

        def initialize(field:, operator:, value:)
          @field = freeze_scalar(field)
          @operator = freeze_scalar(operator)
          @value = freeze_value(value)
          freeze
        end

        def type = :condition

        private

        def freeze_scalar(value)
          return value unless value.is_a?(String)

          value.dup.freeze
        end

        def freeze_value(value)
          case value
          when Array
            value.map { |item| freeze_scalar(item) }.freeze
          else
            freeze_scalar(value)
          end
        end
      end
    end
  end
end
