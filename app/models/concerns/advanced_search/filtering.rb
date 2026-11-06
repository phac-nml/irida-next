# frozen_string_literal: true

# Shared filtering logic for advanced search.
#
# This concern expects the including class to:
# - include `AdvancedSearch::Operators` (for `build_arel_node` and `condition_*` helpers)
# - provide `model_class`
#
# The set of operators and how each one maps to an Arel handler is declared once in
# `AdvancedSearch::OperatorCatalog`; this concern only dispatches to those handlers.
#
# Override points:
# - `normalize_condition_field(condition)` to coerce fields (e.g., id -> puid)
# - `normalize_condition_value(condition)` to coerce values (e.g., enums)
module AdvancedSearch
  # Applies search conditions to build filtered ActiveRecord scopes.
  module Filtering
    extend ActiveSupport::Concern

    private

    def add_condition(scope, condition)
      operator = AdvancedSearch::OperatorCatalog.find(condition.operator)
      return scope unless operator

      field_name = normalize_condition_field(condition)
      node = build_arel_node(field_name, model_class)
      value = normalize_condition_value(condition)

      apply_operator(operator, scope, node, value, field_name)
    end

    # Dispatches a catalog operator to its Arel handler. Exposed so callers that
    # build their own Arel node (e.g. attachment blob columns) can reuse the
    # catalog-driven dispatch.
    def apply_operator(operator, scope, node, value, field_name)
      args = resolve_arel_args(operator.arel_args, value:, field_name:)
      send(operator.arel_handler, scope, node, *args)
    end

    # Resolves an operator's declared argument tokens into concrete handler
    # arguments. Reserved tokens are looked up from the current condition context;
    # any other value (e.g. :eq, :date) is forwarded to the handler literally.
    def resolve_arel_args(arel_args, value:, field_name:)
      arel_args.map do |token|
        case token
        when :value then value
        when :field_name then field_name
        when :model_class then model_class
        when :metadata_key then metadata_key(field_name)
        else token
        end
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
