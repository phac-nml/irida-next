# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Recursive tree walker that translates a GroupNode/ConditionNode tree into
    # an ActiveRecord::Relation via Arel.
    class Executor
      include AdvancedSearch::Operators
      include AdvancedSearch::Filtering

      def initialize(tree, scope)
        @tree = tree
        @scope = scope
      end

      def call
        visit(@tree, @scope)
      end

      private

      def visit(node, scope)
        case node.type
        when :group     then visit_group(node, scope)
        when :condition then visit_condition(node, scope)
        end
      end

      def visit_group(node, base_scope)
        return base_scope if node.nodes.empty?

        child_relations = node.nodes.map { |n| visit(n, base_scope) }
        child_relations.reduce do |acc, rel|
          if node.combinator == 'and'
            acc.and(rel)
          else
            acc.or(rel)
          end
        end
      end

      def visit_condition(node, scope)
        add_condition(scope, node)
      end

      def model_class
        Sample
      end

      def normalize_condition_value(condition)
        return condition.value unless condition.field == 'puid'

        case condition.operator
        when 'in', 'not_in'
          Array(condition.value).map { |v| v.to_s.upcase }
        when '=', '!='
          condition.value.to_s.upcase
        else
          condition.value
        end
      end
    end
  end
end
