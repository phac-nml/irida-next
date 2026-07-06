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

    OPERATOR_HANDLERS = {
      # equals operators
      '=' => :apply_condition_equals,
      'numeric_equals' => :apply_condition_equals,
      'date_equals' => :apply_condition_equals,
      'text_equals' => :apply_condition_equals,
      # not_equals operators
      '!=' => :apply_condition_not_equals,
      'numeric_not_equals' => :apply_condition_not_equals,
      'date_not_equals' => :apply_condition_not_equals,
      'text_not_equals' => :apply_condition_not_equals,
      # contains operators
      'text_contains' => :apply_condition_contains,
      'contains' => :apply_condition_contains,
      # not_contains operators
      'text_not_contains' => :apply_condition_not_contains,
      'not_contains' => :apply_condition_not_contains,
      # greater_than_or_equal operators
      '>=' => :apply_condition_standard_greater_than_or_equal,
      'date_greater_than_equals' => :apply_condition_metadata_date_greater_than_or_equal,
      'numeric_greater_than_equals' => :apply_condition_metadata_numeric_greater_than_or_equal,
      # less_than_or_equal operators
      '<=' => :apply_condition_standard_less_than_or_equal,
      'date_less_than_equals' => :apply_condition_metadata_date_less_than_or_equal,
      'numeric_less_than_equals' => :apply_condition_metadata_numeric_less_than_or_equal,
      # in operators
      'in' => :apply_condition_in,
      'not_in' => :apply_condition_not_in,
      'text_in' => :apply_condition_metadata_in,
      'text_not_in' => :apply_condition_metadata_not_in,
      # exists operators
      'exists' => :apply_condition_exists,
      'not_exists' => :apply_condition_not_exists
    }.freeze

    private

    def add_condition(scope, condition)
      field_name = normalize_condition_field(condition)
      node = build_arel_node(field_name, model_class)
      value = normalize_condition_value(condition)
      # operator = condition.operator

      handler = OPERATOR_HANDLERS[condition.operator]
      return scope unless handler

      send(handler, scope, node, value, field_name)
    end

    def apply_condition_equals(scope, node, value, field_name)
      condition_equals(scope, node, value, field_name)
    end

    def apply_condition_not_equals(scope, node, value, field_name)
      condition_not_equals(scope, node, value, field_name)
    end

    def apply_condition_contains(scope, node, value, field_name)
      condition_contains(scope, node, value, model_class, field_name)
    end

    def apply_condition_not_contains(scope, node, value, field_name)
      condition_not_contains(scope, node, value, model_class, field_name)
    end

    def apply_condition_standard_greater_than_or_equal(scope, node, value, field_name)
      condition_greater_than_or_equal(scope, node, value, metadata_key(field_name))
    end

    def apply_condition_metadata_date_greater_than_or_equal(scope, node, value, _field_name)
      metadata_condition_date_comparison(scope, node, value, :gteq)
    end

    def apply_condition_metadata_numeric_greater_than_or_equal(scope, node, value, _field_name)
      metadata_condition_numeric_comparison(scope, node, value, :gteq)
    end

    def apply_condition_standard_less_than_or_equal(scope, node, value, field_name)
      condition_less_than_or_equal(scope, node, value, metadata_key(field_name))
    end

    def apply_condition_metadata_date_less_than_or_equal(scope, node, value, _field_name)
      metadata_condition_date_comparison(scope, node, value, :lteq)
    end

    def apply_condition_metadata_numeric_less_than_or_equal(scope, node, value, _field_name)
      metadata_condition_numeric_comparison(scope, node, value, :lteq)
    end

    def apply_condition_in(scope, node, value, field_name)
      condition_in(scope, node, value, field_name)
    end

    def apply_condition_not_in(scope, node, value, field_name)
      condition_not_in(scope, node, value, field_name)
    end

    def apply_condition_metadata_in(scope, node, value, _field_name)
      condition_in_metadata(scope, node, value)
    end

    def apply_condition_metadata_not_in(scope, node, value, _field_name)
      condition_not_in_metadata(scope, node, value)
    end

    def apply_condition_exists(scope, node, _value, _field_name)
      condition_exists(scope, node)
    end

    def apply_condition_not_exists(scope, node, _value, _field_name)
      condition_not_exists(scope, node)
    end

    def normalize_condition_field(condition)
      condition.field
    end

    def normalize_condition_value(condition)
      condition.value
    end
  end
end
