# frozen_string_literal: true

module Samples
  module Metadata
    # Atomically updates analysis metadata using a CTE that computes changed fields once.
    class CteAtomicUpdateService < AtomicUpdateService
      private

      def persist_metadata(payload)
        timestamp = Time.current
        result = @sample.class.connection.select_all(atomic_update_sql(payload, timestamp))
        return [] if result.empty?

        assign_persisted_metadata(result.first)
      end

      def assign_persisted_metadata(result)
        @sample.metadata = JSON.parse(result['metadata'])
        @sample.metadata_provenance = JSON.parse(result['metadata_provenance'])
        JSON.parse(result['changed_keys'])
      end

      def atomic_update_sql(payload, timestamp) # rubocop:disable Metrics/MethodLength
        connection = @sample.class.connection
        samples = @sample.class.quoted_table_name
        payload_jsonb = connection.quote(payload.to_json)
        provenance_jsonb = connection.quote(provenance_payload(payload, timestamp).to_json)
        sample_id = connection.quote(@sample.id)
        updated_at = connection.quote(timestamp)

        <<~SQL.squish
          WITH payload AS (
            SELECT key, value FROM jsonb_each(#{payload_jsonb}::jsonb)
          ),
          changed AS (
            SELECT payload.key, payload.value
            FROM payload
            CROSS JOIN #{samples}
            WHERE #{samples}.id = #{sample_id}
              AND #{samples}.metadata -> payload.key IS DISTINCT FROM payload.value
              AND NOT (payload.value = 'null'::jsonb AND #{samples}.metadata -> payload.key IS NULL)
          ),
          updates AS (
            SELECT
              COALESCE(jsonb_object_agg(key, value), '{}'::jsonb) AS metadata,
              COALESCE(
                jsonb_object_agg(key, #{provenance_jsonb}::jsonb -> key),
                '{}'::jsonb
              ) AS metadata_provenance
            FROM changed
          )
          UPDATE #{samples}
          SET
            metadata = jsonb_strip_nulls(#{samples}.metadata || updates.metadata),
            metadata_provenance = jsonb_strip_nulls(
              #{samples}.metadata_provenance || updates.metadata_provenance
            ),
            updated_at = #{updated_at}
          FROM updates
          WHERE #{samples}.id = #{sample_id}
            AND EXISTS (SELECT 1 FROM changed)
          RETURNING #{samples}.metadata, #{samples}.metadata_provenance,
                    COALESCE((SELECT jsonb_agg(key) FROM changed), '[]'::jsonb) AS changed_keys
        SQL
      end
    end
  end
end
