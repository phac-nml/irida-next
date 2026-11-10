# frozen_string_literal: true

# Base service for metadata update service shared logic
class BaseSampleMetadataUpdateService < BaseService # rubocop:disable Metrics/ClassLength
  METADATA_UPDATE_IMPLEMENTATIONS = %w[original atomic cte_atomic].freeze

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
    when 'cte_atomic'
      perform_cte_atomic_metadata_update(sample, metadata, force_update)
    end
  end

  def metadata_update_implementation
    implementation = params.fetch('metadata_update_implementation', 'original')
    return implementation if METADATA_UPDATE_IMPLEMENTATIONS.include?(implementation)

    raise ArgumentError, "Unsupported metadata update implementation: #{implementation}"
  end

  def perform_original_metadata_update(sample, metadata, force_update) # rubocop:disable Metrics/MethodLength
    metadata_changes = { added: [], updated: [], deleted: [], not_updated: [], unchanged: [], not_found: [] }
    sample.with_lock do
      metadata.each do |key, value|
        next unless validate_metadata_value(key, value, sample.name)

        key = strip_whitespaces(key.to_s.downcase)
        value = strip_whitespaces(value.to_s) # remove data types
        status = get_metadata_change_status(sample, key, value, force_update)
        next unless status

        metadata_changes[status] << key
        if %i[updated added].include?(status)
          add_metadata_to_sample(sample, key, value)
        elsif status == :deleted
          remove_metadata_from_sample(sample, key)
        end
      end
      sample.save
    end
    metadata_changes
  end

  def perform_atomic_metadata_update(sample, metadata, force_update)
    metadata = normalized_metadata(sample, metadata)
    return empty_metadata_changes if metadata.empty?

    original_metadata = sample.metadata.dup
    payload = atomic_metadata_payload(metadata)
    persisted_keys = persist_atomic_metadata(sample, payload, force_update) if payload.any?

    persisted_metadata_changes(sample, original_metadata, metadata, persisted_keys || [], force_update)
  end

  def perform_cte_atomic_metadata_update(sample, metadata, force_update)
    metadata = normalized_metadata(sample, metadata)
    return empty_metadata_changes if metadata.empty?

    original_metadata = sample.metadata.dup
    persisted_keys = persist_cte_atomic_metadata(sample, atomic_metadata_payload(metadata), force_update)

    persisted_metadata_changes(sample, original_metadata, metadata, persisted_keys, force_update)
  end

  def normalized_metadata(sample, metadata)
    metadata.filter_map do |key, value|
      next unless validate_metadata_value(key, value, sample.name)

      [strip_whitespaces(key.to_s.downcase), strip_whitespaces(value.to_s)]
    end.to_h
  end

  def persist_atomic_metadata(sample, payload, force_update)
    timestamp = Time.current
    filtered_payload = filtered_metadata_payload(sample, payload, force_update)
    sample.class.where(id: sample.id, project_id: metadata_update_project_id(sample)).update_all( # rubocop:disable Rails/SkipsModelValidations
      metadata: merge_jsonb(sample.class.arel_table[:metadata], filtered_payload),
      metadata_provenance: merge_jsonb(sample.class.arel_table[:metadata_provenance],
                                       filtered_provenance_payload(payload, filtered_payload, timestamp)),
      updated_at: timestamp
    )
    sample.reload
    persisted_metadata_keys(sample, timestamp)
  end

  def persist_cte_atomic_metadata(sample, payload, force_update)
    timestamp = Time.current
    result = sample.class.connection.select_all(cte_atomic_update_sql(sample, payload, timestamp, force_update))
    return [] if result.empty?

    sample.metadata = JSON.parse(result.first['metadata'])
    sample.metadata_provenance = JSON.parse(result.first['metadata_provenance'])
    JSON.parse(result.first['changed_keys'])
  end

  def persisted_metadata_changes(sample, original_metadata, metadata, persisted_keys, force_update)
    metadata.each_with_object(empty_metadata_changes) do |(key, value), changes|
      status = persisted_metadata_change_status(sample, original_metadata, key, value, persisted_keys)
      status = :unchanged if status == :updated && original_metadata[key] == value && !force_update

      changes[status] << key
    end
  end

  def persisted_metadata_change_status(sample, original_metadata, key, value, persisted_keys)
    return deleted_metadata_change_status(sample, original_metadata, key) if value.blank?
    return :not_updated if analysis_metadata_written_by_other_source?(sample, key)
    return :unchanged unless persisted_keys.include?(key)

    original_metadata.key?(key) ? :updated : :added
  end

  def analysis_metadata_written_by_other_source?(sample, key)
    @analysis_id.nil? && sample.metadata_provenance.dig(key, 'source') == 'analysis'
  end

  def deleted_metadata_change_status(sample, original_metadata, key)
    return :not_found unless original_metadata.key?(key)

    sample.metadata.key?(key) ? :unchanged : :deleted
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

  def persisted_metadata_keys(sample, timestamp)
    provenance = Arel::Table.new(:provenance)
    timestamp_path = Arel::Nodes.build_quoted('{updated_at}')
    updated_at = Arel::Nodes::InfixOperation.new('#>>', provenance[:value], timestamp_path)

    sample.class.where(id: sample.id, project_id: metadata_update_project_id(sample))
          .joins('CROSS JOIN LATERAL jsonb_each(samples.metadata_provenance) AS provenance(key, value)')
          .where(updated_at.eq(timestamp.as_json))
          .pluck(Arel.sql('provenance.key'))
  end

  def merge_jsonb(column, payload)
    Arel::Nodes::NamedFunction.new('jsonb_strip_nulls', [Arel::Nodes::InfixOperation.new('||', column, payload)])
  end

  def filtered_metadata_payload(sample, payload, force_update) # rubocop:disable Metrics/AbcSize
    metadata = sample.class.arel_table[:metadata]
    payload_entry = Arel::Table.new(:payload_entry)
    existing_value = Arel::Nodes::InfixOperation.new('->', metadata, payload_entry[:key])
    values_differ = Arel::Nodes::InfixOperation.new('IS DISTINCT FROM', existing_value, payload_entry[:value])
    missing_null_value = payload_entry[:value].eq(Arel.sql("'null'::jsonb")).and(existing_value.eq(nil))
    permitted_update = permitted_metadata_update_sql(sample, payload_entry)
    jsonb_entries = Arel::Nodes::NamedFunction.new('jsonb_each', [jsonb_payload(payload)])
    jsonb_object = Arel::Nodes::NamedFunction.new('jsonb_object_agg', [payload_entry[:key], payload_entry[:value]])
    aggregate = Arel::Nodes::NamedFunction.new('coalesce', [jsonb_object, Arel.sql("'{}'::jsonb")])

    change_condition = force_update ? 'TRUE' : values_differ.to_sql
    jsonb_aggregate(jsonb_entries, aggregate,
                    "#{change_condition} AND NOT (#{missing_null_value.to_sql}) AND #{permitted_update}")
  end

  def permitted_metadata_update_sql(sample, payload_entry)
    return 'TRUE' unless @analysis_id.nil?

    provenance = sample.class.arel_table[:metadata_provenance]
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
    Arel::Nodes::InfixOperation.new('::', Arel::Nodes.build_quoted(payload.to_json), Arel.sql('jsonb'))
  end

  def jsonb_aggregate(entries, aggregate, condition, alias_name = 'payload_entry')
    Arel::Nodes::Grouping.new(
      Arel.sql("SELECT #{aggregate.to_sql} FROM #{entries.to_sql} AS #{alias_name}(key, value) WHERE #{condition}")
    )
  end

  def metadata_update_project_id(sample)
    @project&.id || sample.project_id
  end

  def cte_atomic_update_sql(sample, payload, timestamp, force_update) # rubocop:disable Metrics/MethodLength
    connection = sample.class.connection
    samples = sample.class.quoted_table_name
    payload_jsonb = connection.quote(payload.to_json)
    provenance_jsonb = connection.quote(provenance_payload(payload, timestamp).to_json)
    sample_id = connection.quote(sample.id)
    project_id = connection.quote(metadata_update_project_id(sample))
    updated_at = connection.quote(timestamp)
    permitted_update = cte_permitted_metadata_update_sql(samples)
    change_condition = force_update ? 'TRUE' : "#{samples}.metadata -> payload.key IS DISTINCT FROM payload.value"

    <<~SQL.squish
      WITH payload AS (
        SELECT key, value FROM jsonb_each(#{payload_jsonb}::jsonb)
      ),
      changed AS (
        SELECT payload.key, payload.value
        FROM payload
        CROSS JOIN #{samples}
        WHERE #{samples}.id = #{sample_id}
          AND #{samples}.project_id = #{project_id}
          AND #{change_condition}
          AND NOT (payload.value = 'null'::jsonb AND #{samples}.metadata -> payload.key IS NULL)
          AND #{permitted_update}
      ),
      updates AS (
        SELECT
          COALESCE(jsonb_object_agg(key, value), '{}'::jsonb) AS metadata,
          COALESCE(jsonb_object_agg(key, #{provenance_jsonb}::jsonb -> key), '{}'::jsonb) AS metadata_provenance
        FROM changed
      )
      UPDATE #{samples}
      SET
        metadata = jsonb_strip_nulls(#{samples}.metadata || updates.metadata),
        metadata_provenance = jsonb_strip_nulls(#{samples}.metadata_provenance || updates.metadata_provenance),
        updated_at = #{updated_at}
      FROM updates
      WHERE #{samples}.id = #{sample_id}
        AND #{samples}.project_id = #{project_id}
        AND EXISTS (SELECT 1 FROM changed)
      RETURNING #{samples}.metadata, #{samples}.metadata_provenance,
                COALESCE((SELECT jsonb_agg(key) FROM changed), '[]'::jsonb) AS changed_keys
    SQL
  end

  def cte_permitted_metadata_update_sql(samples)
    return 'TRUE' unless @analysis_id.nil?

    <<~SQL.squish
      (
        payload.value = 'null'::jsonb
        OR #{samples}.metadata_provenance -> payload.key ->> 'source' IS DISTINCT FROM 'analysis'
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
    project_namespace.update_metadata_summary_by_update_service(deleted_metadata,
                                                                added_metadata,
                                                                by_one)
  end
end
