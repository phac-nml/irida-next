# frozen_string_literal: true

require 'graphql/pagination/relation_connection'

module Graphql
  module Searchkick
    # Customizes `RelationConnection` to work with `Searchkick::Relation`s.
    class RelationConnection < GraphQL::Pagination::RelationConnection # rubocop:disable GraphQL/ObjectDescription
      def has_next_page # rubocop:disable Naming/PredicateName
        if @has_next_page.nil?
          @has_next_page = if @before_offset&.positive?
                             true
                           elsif first
                             initial_offset = (after && offset_from_cursor(after)) || 0
                             nodes.total_count > initial_offset + first
                           else
                             false
                           end
        end
        @has_next_page
      end

      def relation_count(relation)
        relation.total_count
      end

      def relation_limit(relation)
        relation.limit_value
      end

      def relation_offset(relation)
        relation.offset_value
      end

      def null_relation(relation)
        relation.limit(0)
      end

      def load_nodes
        @nodes ||= limited_nodes.results # rubocop:disable Naming/MemoizedInstanceVariableName
      end
    end
  end
end
