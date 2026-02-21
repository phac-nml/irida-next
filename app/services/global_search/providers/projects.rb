# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Search provider for projects.
    class Projects < Base
      TYPE = 'projects'

      def search(query:, match_sources:, filters:, limit:)
        return [] if query.blank?

        include_identifier = match_sources.include?('identifier')
        include_name = match_sources.include?('name')
        return [] unless include_identifier || include_name

        project_scope(query:, include_identifier:, include_name:, filters:, limit:)
          .filter_map { |project| build_project_result(project, query) }
          .first(limit)
      end

      private

      def project_scope(query:, include_identifier:, include_name:, filters:, limit:)
        scope = authorized_scope(Project, type: :relation)
                .joins(namespace: :route)
                .includes(namespace: :route)
        scope = apply_created_filters(scope, created_from: filters[:created_from], created_to: filters[:created_to])
        scope = scope.where(search_clause(include_identifier:, include_name:), search_binds(query:))
        scope.order(updated_at: :desc).limit(limit * 4)
      end

      def build_project_result(project, query)
        return unless allowed_to?(:read?, project)

        match = match_details(project, query)

        build_result(
          type: TYPE,
          record_id: project.id,
          title: project.name,
          subtitle: "#{project.puid} · #{project.full_path}",
          url: namespace_project_path(project.parent, project),
          match_tags: match[:tags],
          score_bucket: match[:bucket],
          updated_at: project.updated_at
        )
      end

      def search_clause(include_identifier:, include_name:)
        clauses = []
        clauses << '(projects.id::text = :exact OR namespaces.puid ILIKE :pattern)' if include_identifier
        clauses << '(namespaces.name ILIKE :pattern OR routes.path ILIKE :pattern)' if include_name
        clauses.join(' OR ')
      end

      def match_details(project, query)
        identifier_values = [project.id, project.puid]
        name_values = [project.name, project.path, project.full_path, project.namespace.route&.path]

        return { tags: ['Exact ID'], bucket: SCORE_BUCKET_EXACT_IDENTIFIER } if exact_on_any?(identifier_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_EXACT_NAME } if exact_on_any?(name_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_PREFIX } if prefix_on_any?(identifier_values + name_values, query)

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end
    end
  end
end
