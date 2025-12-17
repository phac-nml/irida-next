# frozen_string_literal: true

require 'graphql/pagination/connection'

module Connections
  # This class implements cursor-based pagination for ActiveRecord models in GraphQL.
  class ActiveRecordCursorPaginateConnection < GraphQL::Pagination::Connection # rubocop:disable GraphQL/ObjectDescription
    def nodes
      load_nodes
      @nodes.records
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

    def load_nodes # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @nodes ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        pagination_params = {}
        if after.present?
          pagination_params[:after] = after
        elsif before.present?
          pagination_params[:before] = before
        end

        pagination_params[:limit] = default_page_size
        if first.present?
          pagination_params[:limit] = first
        elsif last.present?
          pagination_params[:limit] = last
          pagination_params[:forward_pagination] = false
        end

        if arguments.key?(:order_by) && arguments[:order_by].present?
          pagination_params[:order] = if arguments[:order_by].direction.present?
                                        { arguments[:order_by].field => arguments[:order_by].direction.to_sym }
                                      else
                                        { arguments[:order_by].field => :asc }
                                      end
        else
          pagination_params[:order] = { created_at: :asc }
        end

        sliced_nodes = items.cursor_paginate(**pagination_params)
        sliced_nodes.fetch
      end
    end
  end
end
