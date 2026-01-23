# frozen_string_literal: true

module AdvancedSearch
  module Operators
    # Methods for pattern matching search conditions (CONTAINS, NOT CONTAINS, EXISTS)
    module PatternOperators
      extend ActiveSupport::Concern

      private

      def condition_contains(scope, node, value, model_class: nil, field_name: nil)
        search_node = model_class && field_name ? cast_to_text_if_uuid(node, model_class, field_name) : node
        scope.where(search_node.matches("%#{escape_like_wildcards(value)}%"))
      end

      def condition_not_contains(scope, node, value, model_class: nil, field_name: nil)
        search_node = model_class && field_name ? cast_to_text_if_uuid(node, model_class, field_name) : node
        scope.where(node.eq(nil).or(search_node.does_not_match("%#{escape_like_wildcards(value)}%")))
      end

      def condition_exists(scope, node)
        scope.where(node.not_eq(nil))
      end

      def condition_not_exists(scope, node)
        scope.where(node.eq(nil))
      end

      # Cast UUID column to text for text-based operations
      def cast_to_text_if_uuid(node, model_class, field_name)
        return node unless uuid_column?(model_class, field_name)

        Arel::Nodes::NamedFunction.new('CAST', [node.as(Arel::Nodes::SqlLiteral.new('TEXT'))])
      end

      # Check if a field is a UUID column in the given model
      def uuid_column?(model_class, field_name)
        column = model_class.columns_hash[field_name.to_s]
        column&.type == :uuid
      end

      # Escapes SQL LIKE wildcard characters (%, _) to treat them as literal characters
      # @param value [String] the value to escape
      # @return [String] the escaped value
      def escape_like_wildcards(value)
        value.gsub(/[%_\\]/) { |char| "\\#{char}" }
      end
    end
  end
end
