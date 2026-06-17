# frozen_string_literal: true

# Shared filtering logic for advanced search.
#
# This concern expects the including class to:
# - include `AdvancedSearch::Operators` (for `build_arel_node` and `condition_*` helpers)
# - provide `model_class`
#
# Override points:
# - `normalize_condition_value(condition)` to coerce values (e.g., enums)
# - `apply_*_operator` methods for special-case fields (e.g., upcasing PUID)
module AdvancedSearch
  # Applies search conditions to build filtered ActiveRecord scopes.
  module Filtering # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    private

    def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      field_name = normalize_condition_field(condition)
      node = build_arel_node(field_name, model_class)
      value = normalize_condition_value(condition)
      metadata_field = field_name.starts_with?('metadata.')
      operator = condition.operator
      placeholder = false

      if metadata_field && placeholder
        if operator.starts_with?('TEXT_')
          apply_metadata_text_operator(scope, node, value, operator, model_class:, field_name:)
        elsif operator.starts_with?('NUMERIC_')
          apply_metadata_numeric_operator(scope, node, value, operator, field_name:)
        elsif operator.starts_with?('DATE_')
          apply_metadata_date_operator(scope, node, value, operator, field_name:)
        else
          apply_metadata_exists_operator(scope, node, operator)
        end
      elsif placeholder
        case condition.operator
        when '='
          condition_equals(scope, node, value, field_name:)
        when 'in'
          condition_in(scope, node, value, field_name:)
        when '!='
          condition_not_equals(scope, node, value, field_name:)
        when 'not_in'
          condition_not_in(scope, node, value, field_name:)
        when '<='
          scope.where(node.lteq(value))
        when '>='
          scope.where(node.gteq(value))
        when 'contains'
          condition_contains(scope, node, value, model_class:, field_name:)
        when 'not_contains'
          condition_not_contains(scope, node, value, model_class:, field_name:)
        when 'exists'
          condition_exists(scope, node)
        when 'not_exists'
          condition_not_exists(scope, node)
        else
          scope
        end
      else
        case operator
        when '='
          apply_equals_operator_v1(scope, node, value, metadata_field:, field_name:)
        when 'in'
          apply_in_operator_v1(scope, node, value, metadata_field:, field_name:)
        when '!='
          apply_not_equals_operator_v1(scope, node, value, metadata_field:, field_name:)
        when 'not_in'
          apply_not_in_operator_v1(scope, node, value, metadata_field:, field_name:)
        when '<='
          apply_less_than_or_equal_v1(scope, node, value, field: field_name, metadata_field:)
        when '>='
          apply_greater_than_or_equal_v1(scope, node, value, field: field_name, metadata_field:)
        when 'contains'
          condition_contains_v1(scope, node, value, model_class:, field_name:)
        when 'not_contains'
          condition_not_contains_v1(scope, node, value, model_class:, field_name:)
        when 'exists'
          condition_exists_v1(scope, node)
        when 'not_exists'
          condition_not_exists_v1(scope, node)
        else
          scope
        end
      end
    end

    def normalize_condition_field(condition)
      condition.field
    end

    def normalize_condition_value(condition)
      condition.value
    end

    def apply_metadata_exists_operator(scope, node, operator)
      case operator
      when 'EXISTS'
        condition_exists(scope, node)
      when 'NOT_EXISTS'
        scope.where(node.eq(nil))
      end
    end

    def apply_metadata_text_operator(scope, node, value, operator, model_class:, field_name:) # rubocop:disable Metrics/ParameterLists
      case operator
      when 'TEXT_EQUALS'
        metadata_condition_equals(scope, node, value, field_name:)
      when 'TEXT_NOT_EQUALS'
        metadata_condition_not_equals(scope, node, value, field_name:)
      when 'TEXT_CONTAINS'
        condition_contains(scope, node, value, model_class:, field_name:)
      when 'TEXT_NOT_CONTAINS'
        condition_not_contains(scope, node, value, model_class:, field_name:)
      when 'TEXT_IN'
        scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).in(downcase_values(value)))
      when 'TEXT_NOT_IN'
        lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])
        # Include NULL metadata values in negative set operations: NULL is not in the provided set.
        # This maintains consistency with metadata_condition_not_equals, where "not X" includes records without the
        # field.
        scope.where(node.eq(nil).or(lower_function.not_in(downcase_values(value))))
      end
    end

    def apply_metadata_numeric_operator(scope, node, value, operator, field_name:)
      case operator
      when 'NUMERIC_EQUALS'
        metadata_condition_equals(scope, node, value, field_name:)
      when 'NUMERIC_NOT_EQUALS'
        metadata_condition_not_equals(scope, node, value, field_name:)
      when 'NUMERIC_LESS_THAN_EQUALS', 'NUMERIC_GREATER_THAN_EQUALS'
        return scope.none unless valid_numeric_format?(value)

        metadata_condition_numeric_comparison(scope, node, value,
                                              operator == 'NUMERIC_LESS_THAN_EQUALS' ? :lteq : :gteq)
      end
    end

    def apply_metadata_date_operator(scope, node, value, operator, field_name:)
      case operator
      when 'DATE_EQUALS'
        metadata_condition_equals(scope, node, value, field_name:)
      when 'DATE_NOT_EQUALS'
        metadata_condition_not_equals(scope, node, value, field_name:)
      when 'DATE_LESS_THAN_EQUALS', 'DATE_GREATER_THAN_EQUALS'
        return scope.none unless valid_date_format?(value)

        metadata_condition_date_comparison(scope, node, value, operator == 'DATE_LESS_THAN_EQUALS' ? :lteq : :gteq)
      end
    end

    def valid_date_format?(value)
      Date.iso8601(value.to_s)
      true
    rescue ArgumentError
      false
    end

    def valid_numeric_format?(value)
      value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    end

    ##############################

    def apply_less_than_or_equal_v1(scope, node, value, field:, metadata_field:)
      metadata_key = field.delete_prefix('metadata.')
      condition_less_than_or_equal_v1(scope, node, value, metadata_field:, metadata_key:)
    end

    def apply_greater_than_or_equal_v1(scope, node, value, field:, metadata_field:)
      metadata_key = field.delete_prefix('metadata.')
      condition_greater_than_or_equal_v1(scope, node, value, metadata_field:, metadata_key:)
    end

    def apply_equals_operator_v1(scope, node, value, metadata_field:, field_name:)
      condition_equals_v1(scope, node, value, metadata_field:, field_name:)
    end

    def apply_in_operator_v1(scope, node, value, metadata_field:, field_name:)
      condition_in_v1(scope, node, value, metadata_field:, field_name:)
    end

    def apply_not_equals_operator_v1(scope, node, value, metadata_field:, field_name:)
      condition_not_equals_v1(scope, node, value, metadata_field:, field_name:)
    end

    def apply_not_in_operator_v1(scope, node, value, metadata_field:, field_name:)
      condition_not_in_v1(scope, node, value, metadata_field:, field_name:)
    end
  end
end
