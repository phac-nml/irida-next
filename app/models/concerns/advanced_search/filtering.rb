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

    private

    def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      node = build_arel_node(condition, model_class)
      value = normalize_condition_value(condition)
      metadata_field = condition.field.starts_with?('metadata.')

      case condition.operator
      when '='
        apply_equals_operator(scope, node, value, metadata_field:, field_name: condition.field)
      when 'in'
        apply_in_operator(scope, node, value, metadata_field:, field_name: condition.field)
      when '!='
        apply_not_equals_operator(scope, node, value, metadata_field:, field_name: condition.field)
      when 'not_in'
        apply_not_in_operator(scope, node, value, metadata_field:, field_name: condition.field)
      when '<='
        apply_less_than_or_equal(scope, node, value, field: condition.field, metadata_field:)
      when '>='
        apply_greater_than_or_equal(scope, node, value, field: condition.field, metadata_field:)
      when 'contains'
        condition_contains(scope, node, value, model_class:, field_name: condition.field)
      when 'not_contains'
        condition_not_contains(scope, node, value, model_class:, field_name: condition.field)
      when 'exists'
        condition_exists(scope, node)
      when 'not_exists'
        condition_not_exists(scope, node)
      else
        scope
      end
    end

    def normalize_condition_value(condition)
      condition.value
    end

    def apply_less_than_or_equal(scope, node, value, field:, metadata_field:)
      metadata_key = field.delete_prefix('metadata.')
      condition_less_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
    end

    def apply_greater_than_or_equal(scope, node, value, field:, metadata_field:)
      metadata_key = field.delete_prefix('metadata.')
      condition_greater_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
    end

    def apply_equals_operator(scope, node, value, metadata_field:, field_name:)
      condition_equals(scope, node, value, metadata_field:, field_name:)
    end

    def apply_in_operator(scope, node, value, metadata_field:, field_name:)
      condition_in(scope, node, value, metadata_field:, field_name:)
    end

    def apply_not_equals_operator(scope, node, value, metadata_field:, field_name:)
      condition_not_equals(scope, node, value, metadata_field:, field_name:)
    end

    def apply_not_in_operator(scope, node, value, metadata_field:, field_name:)
      condition_not_in(scope, node, value, metadata_field:, field_name:)
    end
  end
end
