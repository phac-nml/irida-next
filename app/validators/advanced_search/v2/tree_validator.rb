# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Validates a GroupNode/ConditionNode tree structure before execution.
    # Returns { valid: bool, errors: [{ path: String, message: String }] }
    class TreeValidator
      VALID_COMBINATORS = %w[and or].freeze
      ARRAY_OPERATORS = %w[in not_in].freeze
      VALUELESS_OPERATORS = %w[exists not_exists].freeze

      def validate(tree)
        return { valid: false, errors: [{ path: 'root', message: 'query tree is required' }] } if tree.nil?

        errors = []
        validate_node(tree, 'root', depth: 0, errors:)
        { valid: errors.empty?, errors: }
      end

      private

      def validate_node(node, path, depth:, errors:)
        unless node.respond_to?(:type)
          errors << { path:, message: 'node must be a group or condition' }
          return
        end

        case node.type
        when :group
          validate_group(node, path, depth:, errors:)
        when :condition
          validate_condition(node, path, errors:)
        else
          errors << { path:, message: "unknown node type: #{node.type.inspect}" }
        end
      end

      def validate_group(node, path, depth:, errors:)
        unless VALID_COMBINATORS.include?(node.combinator)
          errors << { path:, message: "invalid combinator: #{node.combinator.inspect}" }
        end

        node.nodes.each_with_index do |child, i|
          child_path = "#{path}.nodes[#{i}]"
          if child.type == :group
            validate_nested_group(child, child_path, depth:, errors:)
          else
            validate_condition(child, child_path, errors:)
          end
        end
      end

      def validate_nested_group(child, child_path, depth:, errors:)
        if depth >= 1
          errors << { path: child_path,
                      message: 'nesting depth exceeded: sub-groups may only appear directly under root' }
        else
          validate_group(child, child_path, depth: depth + 1, errors:)
        end
      end

      def validate_condition(node, path, errors:)
        if node.operator.blank?
          errors << { path:, message: 'operator is required' }
          return
        end

        validate_condition_field(node, path, errors)
        validate_condition_operator(node, path, errors)
        validate_condition_value(node, path, errors)
      end

      def validate_condition_field(node, path, errors)
        return if FieldConfiguration.valid_field?(node.field)

        errors << { path:, message: "unknown field: #{node.field.inspect}" }
      end

      def validate_condition_operator(node, path, errors)
        return unless FieldConfiguration.valid_field?(node.field)
        return if FieldConfiguration.valid_operator?(node.field, node.operator)

        errors << { path:, message: "invalid operator #{node.operator.inspect} for field #{node.field.inspect}" }
      end

      def validate_condition_value(node, path, errors)
        if ARRAY_OPERATORS.include?(node.operator)
          validate_array_value(node, path, errors)
          return
        end

        return if VALUELESS_OPERATORS.include?(node.operator)
        return if scalar_value?(node.value)

        errors << { path:, message: "operator #{node.operator.inspect} requires a scalar value" }
      end

      def validate_array_value(node, path, errors)
        return if node.value.is_a?(Array)

        errors << { path:, message: "operator #{node.operator.inspect} requires an array value" }
      end

      def scalar_value?(value)
        value.nil? || value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
      end
    end
  end
end
