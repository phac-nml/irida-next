# frozen_string_literal: true

require 'graphql/pagination/connection'

module Connections
  # This class implements cursor-based pagination for ActiveRecord models in GraphQL.
  class ActiveRecordCursorPaginateConnection < GraphQL::Pagination::Connection # rubocop:disable GraphQL/ObjectDescription
    def initialize(items, **args)
      super

      if after.present? && first.nil? && last.present?
        raise GraphQL::ExecutionError, 'When using `after` you must also provide `first` if also providing `last`.'
      elsif before.present? && first.nil? && last.present?
        raise GraphQL::ExecutionError, 'When using `before` you must also provide `last` if also providing `first`.'
      end
    end

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

    def has_previous_page # rubocop:disable Naming/PredicatePrefix,Naming/PredicateMethod
      load_nodes
      @nodes.has_previous?
    end

    def has_next_page # rubocop:disable Naming/PredicatePrefix,Naming/PredicateMethod
      load_nodes
      @nodes.has_next?
    end

    def cursor_for(item)
      load_nodes
      @nodes.cursor_for(item)
    end

    private

    def load_nodes
      @nodes ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        paginator = items.cursor_paginate

        set_order(paginator)
        set_limit(paginator)

        if after.present?
          paginator.after = after
        elsif before.present?
          paginator.before = before
        end

        paginator.fetch
      end
    end

    def set_order(paginator) # rubocop:disable Metrics/AbcSize,Naming/AccessorMethodName
      order_arguments = if arguments.key?(:order_by) && arguments[:order_by].present?
                          if arguments[:order_by].direction.present?
                            { arguments[:order_by].field => resolve_direction(arguments[:order_by].direction.to_sym) }
                          else
                            { arguments[:order_by].field => resolve_direction(:asc) }
                          end
                        else
                          { created_at: resolve_direction(:asc) }
                        end

      paginator.order = order_arguments
    end

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
