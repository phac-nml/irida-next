# frozen_string_literal: true

module Pagination
  # Shared ordering/nullability extraction for active_record_cursor_paginate paginators.
  module ActiveRecordCursorOrdering
    module_function

    def order(scope)
      scope.order_values.to_h do |order|
        [resolve_order_expression(order, scope.table), yield(order.direction)]
      end
    end

    def nullable_columns(scope)
      scope.order_values.filter_map do |order|
        order.expr if order.expr.is_a?(Arel::Nodes::InfixOperation)
      end
    end

    def resolve_order_expression(order, scope_table)
      if order.expr.is_a?(Arel::Attributes::Attribute) && order.expr.relation == scope_table
        order.expr.name
      elsif order.expr.is_a?(Arel::Attributes::Attribute) && order.expr.relation != scope_table
        Arel.sql("#{order.expr.relation.name}.#{order.expr.name}")
      else
        order.expr
      end
    end
    private_class_method :resolve_order_expression
  end
end
