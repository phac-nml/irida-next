# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Search provider for groups.
    class Groups < Base
      TYPE = 'groups'

      def search(query:, match_sources:, filters:, limit:)
        return [] if query.blank?

        include_identifier = match_sources.include?('identifier')
        include_name = match_sources.include?('name')
        return [] unless include_identifier || include_name

        group_scope(query:, include_identifier:, include_name:, filters:, limit:)
          .filter_map { |group| build_group_result(group, query) }
          .first(limit)
      end

      private

      def group_scope(query:, include_identifier:, include_name:, filters:, limit:)
        scope = authorized_scope(Group, type: :relation)
                .joins(:route)
                .includes(:route)
        scope = apply_created_filters(scope, created_from: filters[:created_from], created_to: filters[:created_to])
        scope = scope.where(search_clause(include_identifier:, include_name:), search_binds(query:))
        scope.order(updated_at: :desc).limit(limit * 4)
      end

      def build_group_result(group, query)
        return unless allowed_to?(:read?, group)

        match = match_details(group, query)

        build_result(
          type: TYPE,
          record_id: group.id,
          title: group.name,
          subtitle: "#{group.puid} · #{group.full_path}",
          url: group_path(group),
          match_tags: match[:tags],
          score_bucket: match[:bucket],
          updated_at: group.updated_at
        )
      end

      def search_clause(include_identifier:, include_name:)
        clauses = []
        clauses << '(namespaces.id::text = :exact OR namespaces.puid ILIKE :pattern)' if include_identifier
        clauses << '(namespaces.name ILIKE :pattern OR routes.path ILIKE :pattern)' if include_name
        clauses.join(' OR ')
      end

      def match_details(group, query)
        identifier_values = [group.id, group.puid]
        name_values = [group.name, group.path, group.full_path, group.route&.path]

        return { tags: ['Exact ID'], bucket: SCORE_BUCKET_EXACT_IDENTIFIER } if exact_on_any?(identifier_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_EXACT_NAME } if exact_on_any?(name_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_PREFIX } if prefix_on_any?(identifier_values + name_values, query)

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end
    end
  end
end
