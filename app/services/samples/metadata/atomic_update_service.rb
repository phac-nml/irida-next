# frozen_string_literal: true

module Samples
  module Metadata
    # Atomically applies analysis metadata and generated provenance to a sample.
    class AtomicUpdateService < BaseSampleMetadataUpdateService # rubocop:disable Metrics/ClassLength
      def initialize(sample, analysis_id, metadata)
        super(nil, {})
        @sample = sample
        @analysis_id = analysis_id
        @metadata = metadata
      end

      def execute
        metadata = normalized_metadata
        return empty_metadata_changes if metadata.empty?

        original_metadata = @sample.metadata.dup
        payload = metadata_payload(metadata)
        persisted_keys = persist_metadata(payload) if payload.any?

        metadata_changes = persisted_metadata_changes(original_metadata, metadata, persisted_keys || [])
        update_namespace_metadata_summary(@sample.project.namespace, metadata_changes[:deleted],
                                          metadata_changes[:added], true)

        metadata_changes
      end

      private

      def persist_metadata(payload)
        timestamp = Time.current
        update_sample(payload, timestamp)
        @sample.reload
        persisted_metadata_keys(timestamp)
      end

      def update_sample(payload, timestamp)
        filtered_payload = filtered_metadata_payload(payload)
        # update_all executes one PostgreSQL JSONB update rather than saving a stale Ruby object.
        Sample.where(id: @sample.id).update_all( # rubocop:disable Rails/SkipsModelValidations
          metadata: merge_jsonb(@sample.class.arel_table[:metadata], filtered_payload),
          metadata_provenance: merge_jsonb(@sample.class.arel_table[:metadata_provenance],
                                           filtered_provenance_payload(payload, filtered_payload, timestamp)),
          updated_at: timestamp
        )
      end

      def normalized_metadata
        @metadata.each do |key, value|
          validate_metadata_value(key, value, @sample.name)
        end

        @metadata.to_h do |key, value|
          [
            strip_whitespaces(key.to_s.downcase),
            strip_whitespaces(value.to_s)
          ]
        end
      end

      def persisted_metadata_changes(original_metadata, metadata, persisted_keys)
        metadata.each_with_object(empty_metadata_changes) do |(key, value), changes|
          changes[persisted_metadata_change_status(original_metadata, key, value, persisted_keys)] << key
        end
      end

      def persisted_metadata_change_status(original_metadata, key, value, persisted_keys)
        return deleted_metadata_change_status(original_metadata, key) if value.blank?
        return :not_updated if analysis_metadata_written_by_other_source?(key)
        return :unchanged unless persisted_keys.include?(key)

        original_metadata.key?(key) ? :updated : :added
      end

      def analysis_metadata_written_by_other_source?(key)
        @analysis_id.nil? && @sample.metadata_provenance.dig(key, 'source') == 'analysis'
      end

      def deleted_metadata_change_status(original_metadata, key)
        return :not_found unless original_metadata.key?(key)

        @sample.metadata.key?(key) ? :unchanged : :deleted
      end

      def empty_metadata_changes
        { added: [], updated: [], deleted: [], not_updated: [], unchanged: [], not_found: [] }
      end

      def validate_metadata_value(key, value, sample_name)
        return unless value.is_a?(Hash)

        raise ArgumentError,
              I18n.t('services.samples.metadata.nested_metadata', sample_name:, key:)
      end

      def metadata_payload(metadata)
        metadata.transform_values(&:presence)
      end

      def provenance_payload(payload, timestamp)
        timestamp = timestamp.as_json

        payload.transform_values do |value|
          value.nil? ? nil : { source: 'analysis', id: @analysis_id, updated_at: timestamp }
        end
      end

      def persisted_metadata_keys(timestamp)
        provenance = Arel::Table.new(:provenance)
        timestamp_path = Arel::Nodes.build_quoted('{updated_at}')
        updated_at = Arel::Nodes::InfixOperation.new('#>>', provenance[:value], timestamp_path)
        samples = @sample.class.where(id: @sample.id)

        samples.joins('CROSS JOIN LATERAL jsonb_each(samples.metadata_provenance) AS provenance(key, value)')
               .where(updated_at.eq(timestamp.as_json))
               .pluck(Arel.sql('provenance.key'))
      end

      def merge_jsonb(column, payload)
        merged_jsonb = Arel::Nodes::InfixOperation.new('||', column, payload)

        Arel::Nodes::NamedFunction.new('jsonb_strip_nulls', [merged_jsonb])
      end

      def filtered_metadata_payload(payload) # rubocop:disable Metrics/AbcSize
        metadata = @sample.class.arel_table[:metadata]
        payload_entry = Arel::Table.new(:payload_entry)
        existing_value = Arel::Nodes::InfixOperation.new('->', metadata, payload_entry[:key])
        values_differ = Arel::Nodes::InfixOperation.new('IS DISTINCT FROM', existing_value, payload_entry[:value])
        missing_null_value = payload_entry[:value].eq(Arel.sql("'null'::jsonb"))
                                                  .and(existing_value.eq(nil))
        permitted_update = permitted_metadata_update_sql(payload_entry)
        jsonb_entries = Arel::Nodes::NamedFunction.new('jsonb_each', [jsonb_payload(payload)])
        jsonb_object = Arel::Nodes::NamedFunction.new('jsonb_object_agg', [payload_entry[:key], payload_entry[:value]])
        aggregate = Arel::Nodes::NamedFunction.new('coalesce', [jsonb_object, Arel.sql("'{}'::jsonb")])

        jsonb_aggregate(
          jsonb_entries,
          aggregate,
          "#{values_differ.to_sql} AND NOT (#{missing_null_value.to_sql}) AND #{permitted_update}"
        )
      end

      def permitted_metadata_update_sql(payload_entry)
        return 'TRUE' unless @analysis_id.nil?

        provenance = @sample.class.arel_table[:metadata_provenance]
        source = Arel::Nodes::InfixOperation.new(
          '->>',
          Arel::Nodes::InfixOperation.new('->', provenance, payload_entry[:key]),
          Arel::Nodes.build_quoted('source')
        )
        clearing_value = payload_entry[:value].eq(Arel.sql("'null'::jsonb"))
        user_writable = Arel::Nodes::InfixOperation.new(
          'IS DISTINCT FROM',
          source,
          Arel::Nodes.build_quoted('analysis')
        )

        clearing_value.or(user_writable).to_sql
      end

      def filtered_provenance_payload(payload, filtered_payload, timestamp)
        provenance_entry = Arel::Table.new(:provenance_entry)
        jsonb_entries = Arel::Nodes::NamedFunction.new('jsonb_each',
                                                       [jsonb_payload(provenance_payload(payload, timestamp))])
        jsonb_object = Arel::Nodes::NamedFunction.new('jsonb_object_agg',
                                                      [provenance_entry[:key], provenance_entry[:value]])
        includes_key = Arel::Nodes::InfixOperation.new('?', filtered_payload, provenance_entry[:key])
        aggregate = Arel::Nodes::NamedFunction.new('coalesce', [jsonb_object, Arel.sql("'{}'::jsonb")])

        jsonb_aggregate(jsonb_entries, aggregate, includes_key.to_sql, 'provenance_entry')
      end

      def jsonb_payload(payload)
        Arel::Nodes::InfixOperation.new(
          '::',
          Arel::Nodes.build_quoted(payload.to_json),
          Arel.sql('jsonb')
        )
      end

      def jsonb_aggregate(entries, aggregate, condition, alias_name = 'payload_entry')
        Arel::Nodes::Grouping.new(
          Arel.sql(
            "SELECT #{aggregate.to_sql} FROM #{entries.to_sql} AS #{alias_name}(key, value) WHERE #{condition}"
          )
        )
      end
    end
  end
end
