# frozen_string_literal: true

# Base service for metadata update service shared logic
class BaseSampleMetadataUpdateService < BaseService # rubocop:disable Metrics/ClassLength
  METADATA_UPDATE_IMPLEMENTATIONS = %w[original atomic].freeze

  def initialize(user = nil, params = {})
    super
  end

  private

  def perform_metadata_update(sample, metadata, force_update)
    case metadata_update_implementation
    when 'original'
      perform_original_metadata_update(sample, metadata, force_update)
    when 'atomic'
      perform_atomic_metadata_update(sample, metadata, force_update)
    end
  end

  def metadata_update_implementation
    default_implementation = Flipper.enabled?(:atomic_metadata_updates) ? 'atomic' : 'original'
    implementation = params.fetch('metadata_update_implementation', default_implementation)
    return implementation if METADATA_UPDATE_IMPLEMENTATIONS.include?(implementation)

    raise ArgumentError, "Unsupported metadata update implementation: #{implementation}"
  end

  def perform_original_metadata_update(sample, metadata, force_update)
    metadata_changes = empty_metadata_changes
    sample.with_lock do
      normalized_metadata(sample, metadata).each do |key, value|
        status = get_metadata_change_status(sample, key, value, force_update)
        next unless status

        metadata_changes[status] << key
        if %i[updated added].include?(status)
          add_metadata_to_sample(sample, key, value)
        elsif status == :deleted
          remove_metadata_from_sample(sample, key)
        end
      end
      sample.save if metadata_changes.values_at(:added, :updated, :deleted).any?(&:any?)
    end
    metadata_changes
  end

  # Single correlated UPDATE ... RETURNING statement. No separate relation scan of `samples`
  # occurs, so no explicit row lock is required for the "is this writable" decision to be safe
  # against concurrent writers: the writability/change checks are scalar subqueries correlated
  # directly to the row being updated, which PostgreSQL's EvalPlanQual conflict resolution
  # refreshes against the latest committed tuple when blocked by a concurrent writer. Metadata
  # and provenance are merged in one combined scan over the payload. RETURNING derives
  # persisted_keys from provenance and existing_keys from the pre-update Logidze history,
  # avoiding a second round-trip query.
  def perform_atomic_metadata_update(sample, metadata, force_update)
    metadata = normalized_metadata(sample, metadata)
    return empty_metadata_changes if metadata.empty?

    payload = atomic_metadata_payload(metadata)
    persisted_metadata = persist_atomic_metadata(sample, payload, force_update)
    metadata_changes = persisted_metadata_changes(sample, metadata, persisted_metadata, force_update)

    broadcast_atomic_metadata_update(sample, metadata_changes)
    metadata_changes
  end

  def normalized_metadata(sample, metadata)
    # to_h: ActionController::Parameters (e.g. deletion_params) doesn't implement filter_map, unlike Hash
    metadata.to_h.filter_map do |key, value|
      next unless validate_metadata_value(key, value, sample.name)

      [strip_whitespaces(key.to_s.downcase), strip_whitespaces(value.to_s)] # to_s removes data types
    end.to_h
  end

  def persist_atomic_metadata(sample, payload, force_update)
    timestamp = Time.current
    sql = atomic_update_sql(sample, payload, timestamp, force_update)
    result = sample.class.connection.select_all(sql)
    return { persisted_keys: [], existing_metadata: {} } if result.empty?

    row = result.first
    sample.metadata = JSON.parse(row['metadata'])
    sample.metadata_provenance = JSON.parse(row['metadata_provenance'])
    atomic_metadata_result(row)
  end

  def atomic_metadata_result(row)
    existing_history = JSON.parse(row.fetch('existing_metadata'))
    {
      persisted_keys: JSON.parse(row.fetch('persisted_keys')),
      existing_metadata: existing_history['metadata']
    }
  end

  def persisted_metadata_changes(sample, metadata, persisted_metadata, force_update)
    existing_metadata = persisted_metadata[:existing_metadata]
    existing_keys = existing_metadata.keys
    metadata.each_with_object(empty_metadata_changes) do |(key, value), changes|
      status = persisted_metadata_change_status(sample, key, value, persisted_metadata[:persisted_keys], existing_keys)
      status = :unchanged if status == :updated && existing_metadata[key] == value && !force_update

      changes[status] << key
    end
  end

  def persisted_metadata_change_status(sample, key, value, persisted_keys, existing_keys)
    return deleted_metadata_change_status(sample, key, existing_keys) if value.blank?
    return :not_updated if analysis_metadata_written_by_other_source?(sample, key)
    return :unchanged unless persisted_keys.include?(key)

    existing_keys.include?(key) ? :updated : :added
  end

  def analysis_metadata_written_by_other_source?(sample, key)
    @analysis_id.nil? && sample.metadata_provenance.dig(key, 'source') == 'analysis'
  end

  def deleted_metadata_change_status(sample, key, existing_keys)
    return :unchanged if sample.metadata.key?(key)

    existing_keys.include?(key) ? :deleted : :not_found
  end

  def empty_metadata_changes
    { added: [], updated: [], deleted: [], not_updated: [], unchanged: [], not_found: [] }
  end

  def atomic_metadata_payload(metadata)
    metadata.transform_values(&:presence)
  end

  def provenance_payload(payload, timestamp)
    payload.transform_values do |value|
      next if value.nil?

      {
        source: metadata_provenance_source,
        id: metadata_provenance_id,
        updated_at: timestamp.as_json
      }
    end
  end

  def metadata_provenance_source
    @analysis_id.nil? ? 'user' : 'analysis'
  end

  def metadata_provenance_id
    @analysis_id || current_user.id
  end

  def metadata_update_project_id(sample)
    @project&.id || sample.project_id
  end

  def broadcast_atomic_metadata_update(sample, metadata_changes)
    return if Sample.suppressed_turbo_broadcasts
    return if metadata_changes.values_at(:added, :updated, :deleted).all?(&:empty?)

    ActiveRecord.after_all_transactions_commit do
      sample.project.broadcast_refresh_later_to_samples_table
    end
  end

  # Single correlated UPDATE ... RETURNING statement: merges metadata and provenance in one
  # combined pass over the payload, and derives persisted_keys from RETURNING's post-write
  # metadata_provenance instead of a second round-trip query. No relation (`samples`) is scanned
  # via a separate JOIN/CTE, so no explicit row lock is required for the "is this writable"
  # decision to be safe against concurrent writers: the writability/change checks are scalar
  # subqueries correlated directly to the row being updated, which PostgreSQL's EvalPlanQual
  # conflict resolution refreshes against the latest committed tuple when blocked by a
  # concurrent writer. Classification (added/updated/deleted/...) is intentionally left to the
  # already-tested persisted_metadata_changes/persisted_metadata_change_status. Existing keys
  # come from the newest metadata-bearing Logidze version before this update's timestamp, so they
  # reflect the row state this UPDATE changed.
  def atomic_update_sql(sample, payload, timestamp, force_update) # rubocop:disable Metrics/MethodLength
    connection = sample.class.connection
    samples = sample.class.quoted_table_name
    payload_jsonb = connection.quote(payload.to_json)
    provenance_jsonb = connection.quote(provenance_payload(payload, timestamp).to_json)
    sample_id = connection.quote(sample.id)
    project_id = connection.quote(metadata_update_project_id(sample))
    updated_at_json = connection.quote(timestamp.as_json)
    writable = atomic_writable_sql(samples, force_update)
    entries = "jsonb_each(#{payload_jsonb}::jsonb) AS payload_entry(key, value)"

    <<~SQL.squish
      UPDATE #{samples}
      SET
        metadata = jsonb_strip_nulls(#{samples}.metadata || (
          SELECT COALESCE(jsonb_object_agg(payload_entry.key, payload_entry.value), '{}'::jsonb)
          FROM #{entries} WHERE #{writable}
        )),
        metadata_provenance = jsonb_strip_nulls(#{samples}.metadata_provenance || (
          SELECT COALESCE(jsonb_object_agg(payload_entry.key, #{provenance_jsonb}::jsonb -> payload_entry.key), '{}'::jsonb)
          FROM #{entries} WHERE #{writable}
        )),
        updated_at = CASE
          WHEN EXISTS (SELECT 1 FROM #{entries} WHERE #{writable}) THEN clock_timestamp()
          ELSE #{samples}.updated_at
        END
      WHERE #{samples}.id = #{sample_id}
        AND #{samples}.project_id = #{project_id}
      RETURNING #{samples}.metadata, #{samples}.metadata_provenance,
        (
          SELECT COALESCE(jsonb_agg(kv.key), '[]'::jsonb)
          FROM jsonb_each(#{samples}.metadata_provenance) AS kv(key, value)
          WHERE kv.value ->> 'updated_at' = #{updated_at_json}
        ) AS persisted_keys,
        jsonb_build_object(
          'metadata',
          COALESCE(
            (
              SELECT (history_entry.value -> 'c' ->> 'metadata')::jsonb
              FROM jsonb_array_elements(COALESCE(#{samples}.log_data -> 'h', '[]'::jsonb)) AS history_entry(value)
              WHERE history_entry.value -> 'c' ? 'metadata'
                AND (history_entry.value ->> 'ts')::bigint <
                  (EXTRACT(EPOCH FROM #{samples}.updated_at) * 1000)::bigint
              ORDER BY (history_entry.value ->> 'ts')::bigint DESC,
                       (history_entry.value ->> 'v')::integer DESC
              LIMIT 1
            ),
            '{}'::jsonb
          )
        ) AS existing_metadata
    SQL
  end

  def atomic_writable_sql(samples, force_update)
    permitted = atomic_permitted_sql(samples)
    change_condition = if force_update
                         'TRUE'
                       else
                         "#{samples}.metadata -> payload_entry.key IS DISTINCT FROM payload_entry.value"
                       end

    <<~SQL.squish
      #{change_condition}
      AND NOT (payload_entry.value = 'null'::jsonb AND #{samples}.metadata -> payload_entry.key IS NULL)
      AND #{permitted}
    SQL
  end

  def atomic_permitted_sql(samples)
    return 'TRUE' unless @analysis_id.nil?

    <<~SQL.squish
      (
        payload_entry.value = 'null'::jsonb
        OR #{samples}.metadata_provenance -> payload_entry.key ->> 'source' IS DISTINCT FROM 'analysis'
      )
    SQL
  end

  def remove_metadata_from_sample(sample, key)
    sample.metadata.delete(key)
    sample.metadata_provenance.delete(key)
  end

  def add_metadata_to_sample(sample, key, value)
    sample.metadata_provenance[key] =
      if @analysis_id.nil?
        { source: 'user', id: current_user.id, updated_at: Time.current }
      else
        { source: 'analysis', id: @analysis_id, updated_at: Time.current }
      end
    sample.metadata[key] = value
  end

  def get_metadata_change_status(sample, key, value, force_update) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if value.blank?
      sample.field?(key) ? :deleted : :not_found
    elsif sample.metadata_provenance.key?(key) && @analysis_id.nil? &&
          sample.metadata_provenance[key]['source'] == 'analysis'
      :not_updated
    elsif sample.field?(key) && sample.metadata[key] == value
      force_update ? :updated : :unchanged
    else
      sample.field?(key) ? :updated : :added
    end
  end

  def update_namespace_metadata_summary(project_namespace, deleted_metadata, added_metadata, by_one)
    return if deleted_metadata.empty? && added_metadata.empty?

    project_namespace.update_metadata_summary_by_update_service(deleted_metadata,
                                                                added_metadata,
                                                                by_one)
  end
end
