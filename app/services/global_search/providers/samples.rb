# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Search provider for samples.
    class Samples < Base # rubocop:disable Metrics/ClassLength
      TYPE = 'samples'

      def search(query:, match_sources:, filters:, limit:)
        return [] if query.blank?

        match_options = sample_match_options(match_sources)
        return [] unless match_options.values.any?

        readable_project_ids = readable_sample_project_ids
        return [] if readable_project_ids.empty?

        sample_scope(
          query:,
          match_options:,
          filters:,
          readable_project_ids:,
          limit:
        ).filter_map do |sample|
          build_sample_result(sample, query, include_metadata: match_options[:include_metadata])
        end
         .first(limit)
      end

      private

      def sample_match_options(match_sources)
        {
          include_identifier: match_sources.include?('identifier'),
          include_name: match_sources.include?('name'),
          include_metadata: match_sources.include?('metadata')
        }
      end

      def readable_sample_project_ids
        @readable_sample_project_ids ||= authorized_scope(Project, type: :relation)
                                         .select { |project| allowed_to?(:read_sample?, project) }
                                         .map(&:id)
      end

      def sample_scope(query:, match_options:, filters:, readable_project_ids:, limit:)
        scope = Sample.where(project_id: readable_project_ids).includes(project: :namespace)
        scope = apply_created_filters(scope, created_from: filters[:created_from], created_to: filters[:created_to])
        scope = scope.where(search_clause(**match_options), search_binds(query:))
        scope.order(updated_at: :desc).limit(limit * 6)
      end

      def build_sample_result(sample, query, include_metadata:)
        match = match_details(sample, query, include_metadata:)

        build_result(
          type: TYPE,
          record_id: sample.id,
          title: sample.name,
          subtitle: "#{sample.puid} · #{sample.project.name}",
          url: sample_path(sample),
          match_tags: match[:tags],
          score_bucket: match[:bucket],
          updated_at: sample.updated_at,
          context_label: sample.project.name,
          context_url: namespace_project_path(sample.project.parent, sample.project)
        )
      end

      def search_clause(include_identifier:, include_name:, include_metadata:)
        clauses = []
        clauses << '(samples.id::text = :exact OR samples.puid ILIKE :pattern)' if include_identifier
        clauses << '(samples.name ILIKE :pattern)' if include_name
        clauses << metadata_key_clause if include_metadata
        clauses << metadata_value_clause if include_metadata
        clauses.join(' OR ')
      end

      def metadata_key_clause
        <<~SQL.squish
          EXISTS (
            SELECT 1
            FROM jsonb_each_text(COALESCE(samples.metadata, '{}'::jsonb)) AS kv(key, value)
            WHERE kv.key ILIKE :pattern
          )
        SQL
      end

      def metadata_value_clause
        <<~SQL.squish
          EXISTS (
            SELECT 1
            FROM jsonb_each_text(COALESCE(samples.metadata, '{}'::jsonb)) AS kv(key, value)
            WHERE kv.value ILIKE :pattern
          )
        SQL
      end

      def match_details(sample, query, include_metadata:)
        identifier_values = [sample.id, sample.puid]
        name_values = [sample.name]

        return { tags: ['Exact ID'], bucket: SCORE_BUCKET_EXACT_IDENTIFIER } if exact_on_any?(identifier_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_EXACT_NAME } if exact_on_any?(name_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_PREFIX } if prefix_on_any?(identifier_values + name_values, query)

        return metadata_match(sample, query) if include_metadata

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end

      def metadata_match(sample, query)
        metadata = sample.metadata || {}
        metadata_keys = metadata.keys
        metadata_values = metadata.values

        if exact_metadata_key_match?(metadata_keys, query)
          return { tags: ['Metadata key'], bucket: SCORE_BUCKET_METADATA_KEY }
        end

        if contains_metadata_key_match?(metadata_keys, query)
          return { tags: ['Metadata key'], bucket: SCORE_BUCKET_METADATA_VALUE }
        end

        if contains_metadata_value_match?(metadata_values, query)
          return { tags: ['Metadata value'], bucket: SCORE_BUCKET_METADATA_VALUE }
        end

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end

      def exact_metadata_key_match?(keys, query)
        keys.any? { |key| exact_match?(key, query) }
      end

      def contains_metadata_key_match?(keys, query)
        keys.any? { |key| contains_match?(key, query) }
      end

      def contains_metadata_value_match?(values, query)
        values.any? { |value| contains_match?(value, query) }
      end
    end
  end
end
