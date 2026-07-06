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
  module Filtering
    extend ActiveSupport::Concern

    COMPARISON_OPERATORS = ['numeric_less_than_equals', 'numeric_greater_than_equals', 'date_less_than_equals',
                            'date_greater_than_equals', '<=', '>='].freeze
    EQUALITY_OPERATORS = ['numeric_equals', 'numeric_not_equals', 'date_equals', 'date_not_equals', 'text_equals',
                          'text_not_equals', '=', '!='].freeze
    PATTERN_OPERATORS = %w[text_contains text_not_contains contains not_contains].freeze
    SET_OPERATORS = %w[text_in text_not_in in not_in].freeze
    EXISTENCE_OPERATORS = %w[exists not_exists].freeze

    private

    def add_condition(scope, condition) # rubocop:disable Metrics/MethodLength
      field_name = normalize_condition_field(condition)
      node = build_arel_node(field_name, model_class)
      value = normalize_condition_value(condition)
      operator = condition.operator
      case operator
      when *COMPARISON_OPERATORS
        apply_comparison_operators(scope, node, value, operator, field_name:)
      when *EQUALITY_OPERATORS
        apply_equality_operators(scope, node, value, operator, field_name:)
      when *PATTERN_OPERATORS
        apply_pattern_operators(scope, node, value, operator, model_class:, field_name:)
      when *SET_OPERATORS
        apply_set_operators(scope, node, value, operator, field_name:)
      when *EXISTENCE_OPERATORS
        apply_existence_operators(scope, node, operator)
      else
        scope
      end
    end

    # rubocop:disable Metrics/ParameterLists
    def apply_comparison_operators(scope, node, value, operator, field_name:)
      case operator
      when 'numeric_less_than_equals', 'numeric_greater_than_equals'
        metadata_condition_numeric_comparison(scope, node, value,
                                              operator == 'numeric_less_than_equals' ? :lteq : :gteq)
      when 'date_less_than_equals', 'date_greater_than_equals'
        metadata_condition_date_comparison(scope, node, value, operator == 'date_less_than_equals' ? :lteq : :gteq)
      when '<='
        condition_less_than_or_equal(scope, node, value, metadata_key: metadata_key(field_name))
      when '>='
        condition_greater_than_or_equal(scope, node, value, metadata_key: metadata_key(field_name))
      end
    end

    def apply_equality_operators(scope, node, value, operator, field_name:)
      case operator
      when 'numeric_equals', 'date_equals', 'text_equals', '='
        condition_equals(scope, node, value, field_name:)
      when 'numeric_not_equals', 'date_not_equals', 'text_not_equals', '!='
        condition_not_equals(scope, node, value, field_name:)
      end
    end

    def apply_pattern_operators(scope, node, value, operator, model_class:, field_name:)
      case operator
      when 'text_contains', 'contains'
        condition_contains(scope, node, value, model_class:, field_name:)
      when 'text_not_contains', 'not_contains'
        condition_not_contains(scope, node, value, model_class:, field_name:)
      end
    end

    def apply_set_operators(scope, node, value, operator, field_name:)
      case operator
      when 'text_in'
        condition_in_metadata(scope, node, value)
      when 'text_not_in'
        condition_not_in_metadata(scope, node, value)
      when 'in'
        condition_in(scope, node, value, field_name:)
      when 'not_in'
        condition_not_in(scope, node, value, field_name:)
      end
    end
    # rubocop:enable Metrics/ParameterLists

    def apply_existence_operators(scope, node, operator)
      if operator == 'exists'
        condition_exists(scope, node)
      else
        condition_not_exists(scope, node)
      end
    end

    def normalize_condition_field(condition)
      condition.field
    end

    def normalize_condition_value(condition)
      condition.value
    end
  end
end
