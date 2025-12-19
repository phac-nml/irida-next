# frozen_string_literal: true

require 'graphql/pagination/connection'

module Connections
  # This class implements cursor-based pagination for ActiveRecord models in GraphQL.
  # It extends the GraphQL::Pagination::Connection class to provide custom pagination logic.
  # It supports both forward and backward pagination using `first`, `last`, `after`, and `before` arguments.
  # It also allows sorting based on specified fields and directions.
  class ActiveRecordCursorPaginateConnection < GraphQL::Pagination::Connection # rubocop:disable GraphQL/ObjectDescription,Metrics/ClassLength
    # @return [String, nil] the client-provided cursor. `""` and `"null"` is treated as `nil`.
    def before
      if defined?(@before)
        @before
      else
        @before = ['', 'null'].include?(@before_value) ? nil : @before_value
      end
    end

    # @return [String, nil] the client-provided cursor. `""` and `"null"` is treated as `nil`.
    def after
      if defined?(@after)
        @after
      else
        @after = ['', 'null'].include?(@after_value) ? nil : @after_value
      end
    end

    def initialize(items, **args)
      super

      if after.present? && first.nil? && last.present?
        raise GraphQL::ExecutionError, 'When using `after` you must also provide `first` if also providing `last`.'
      elsif before.present? && last.nil? && first.present?
        raise GraphQL::ExecutionError, 'When using `before` you must also provide `last` if also providing `first`.'
      end
    end

    # Retrieve the nodes for the current page.
    # @return [Array<Object>] The list of nodes for the current page.
    def nodes # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      load_nodes
      records = if @inverted
                  @nodes.records.reverse
                else
                  @nodes.records
                end

      if before.nil? && first.present? && last.present? && last < first
        records.last(last)
      elsif after.nil? && last.present? && first.present? && first < last
        records.first(first)
      else
        records
      end
    end

    # Check if there is a previous page of results.
    # @return [Boolean] True if there is a previous page, false otherwise.
    def has_previous_page # rubocop:disable Naming/PredicatePrefix,Naming/PredicateMethod
      load_nodes
      @nodes.has_previous?
    end

    # Check if there is a next page of results.
    # @return [Boolean] True if there is a next page, false otherwise.
    def has_next_page # rubocop:disable Naming/PredicatePrefix,Naming/PredicateMethod
      load_nodes
      @nodes.has_next?
    end

    # Get the cursor for a specific item.
    # @param item [Object] The item to get the cursor for.
    # @return [String] The cursor for the item.
    def cursor_for(item)
      load_nodes
      @nodes.cursor_for(item)
    end

    private

    # Load the nodes using cursor-based pagination.
    # @return [ActiveRecordCursorPaginate::Result] The paginated result set.
    def load_nodes
      @nodes ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        paginator = items.cursor_paginate

        set_order(paginator)
        set_nullable_columns(paginator)
        set_limit(paginator)

        if after.present?
          paginator.after = after
        elsif before.present?
          paginator.before = before
        end

        paginator.fetch
      end
    end

    # Set the order for the paginator based on the order_values present in the ActiveRecord query.
    # @param paginator [ActiveRecordCursorPaginate::Paginator] The paginator to set the order for.
    # @return [void]
    def set_order(paginator) # rubocop:disable Naming/AccessorMethodName,Metrics/AbcSize
      paginator.order = items.order_values.to_h do |order|
        if order.expr.is_a?(Arel::Attributes::Attribute) && order.expr.relation == items.table
          [order.expr.name, resolve_direction(order.direction)]
        elsif order.expr.is_a?(Arel::Attributes::Attribute) && order.expr.relation != items.table
          [Arel.sql("#{order.expr.relation.name}.#{order.expr.name}"), resolve_direction(order.direction)]
        else
          [order.expr, resolve_direction(order.direction)]
        end
      end
    end

    # Set the nullable columns for the paginator based on the order_values present in the ActiveRecord query.
    # @param paginator [ActiveRecordCursorPaginate::Paginator] The paginator to set the nullable columns for.
    # @return [void]
    def set_nullable_columns(paginator) # rubocop:disable Naming/AccessorMethodName
      paginator.nullable_columns = items.order_values.map do |order|
        order.expr if order.expr.is_a?(Arel::Nodes::InfixOperation)
      end.compact
    end

    # Determine the direction of sorting based on pagination arguments
    # and whether the results need to be inverted.
    # Returns the resolved direction.
    # @param direction [Symbol] The initial sorting direction (:asc or :desc).
    # @return [Symbol] The resolved sorting direction.
    def resolve_direction(direction) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
      @inverted = false
      return direction if (first.present? && after.present?) || (before.present? && last.present?)

      if after.nil? && before.nil? && first.nil? && last.present?
        @inverted = true
        if direction == :asc
          :desc
        else
          :asc
        end
      else
        direction
      end
    end

    # Set the limit for the paginator based on the provided pagination arguments.
    # @param paginator [ActiveRecordCursorPaginate::Paginator] The paginator to set the limit for.
    # @return [void]
    def set_limit(paginator) # rubocop:disable Naming/AccessorMethodName,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      paginator.limit = if first.present? && (after.present? || (before.present? && last.nil?) || before.nil?)
                          first
                        elsif last.present? && (before.present? || (after.present? && first.nil?) || after.nil?)
                          last
                        else
                          first || last || default_page_size
                        end
    end
  end
end
