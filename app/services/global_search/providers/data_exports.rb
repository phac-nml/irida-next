# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Search provider for current-user data exports.
    class DataExports < Base
      TYPE = 'data_exports'

      def search(query:, match_sources:, filters:, limit:)
        return [] if query.blank?

        include_identifier = match_sources.include?('identifier')
        include_name = match_sources.include?('name')
        return [] unless include_identifier || include_name

        data_export_scope(query:, include_identifier:, include_name:, filters:, limit:)
          .filter_map { |data_export| build_data_export_result(data_export, query) }
          .first(limit)
      end

      private

      def data_export_scope(query:, include_identifier:, include_name:, filters:, limit:)
        scope = DataExport.where(user_id: current_user.id)
        scope = apply_created_filters(scope, created_from: filters[:created_from], created_to: filters[:created_to])
        scope = scope.where(search_clause(include_identifier:, include_name:), search_binds(query:))
        scope.order(updated_at: :desc).limit(limit * 4)
      end

      def build_data_export_result(data_export, query)
        return unless allowed_to?(:read_export?, data_export)

        match = match_details(data_export, query)

        build_result(
          type: TYPE,
          record_id: data_export.id,
          title: data_export.name.presence || data_export.id,
          subtitle: "#{data_export.export_type} · #{data_export.status}",
          url: data_export_path(data_export),
          match_tags: match[:tags],
          score_bucket: match[:bucket],
          updated_at: data_export.updated_at
        )
      end

      def search_clause(include_identifier:, include_name:)
        clauses = []
        clauses << '(data_exports.id::text = :exact)' if include_identifier
        clauses << '(data_exports.name ILIKE :pattern)' if include_name
        clauses.join(' OR ')
      end

      def match_details(data_export, query)
        identifier_values = [data_export.id]
        name_values = [data_export.name]

        return { tags: ['Exact ID'], bucket: SCORE_BUCKET_EXACT_IDENTIFIER } if exact_on_any?(identifier_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_EXACT_NAME } if exact_on_any?(name_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_PREFIX } if prefix_on_any?(name_values, query)

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end
    end
  end
end
