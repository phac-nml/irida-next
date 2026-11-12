# frozen_string_literal: true

require_relative '../config/environment'
require 'benchmark/ips'

# Compares 100-sample bulk metadata updates without retaining benchmark records.
class BulkSampleMetadataUpdateBenchmark # rubocop:disable Metrics/ClassLength
  SAMPLE_COUNT = 100

  IMPLEMENTATIONS = {
    'existing bulk update service' => 'original',
    'atomic bulk update service' => 'atomic',
    'CTE atomic bulk update service' => 'cte_atomic',
    'classified atomic bulk update service' => 'classified_atomic'
  }.freeze

  def initialize(sample, user, analysis_id, metadata_counts)
    @project = sample.project
    @user = user
    @analysis_id = analysis_id
    @metadata_counts = metadata_counts
    @counter = 0
    @sample_sets = IMPLEMENTATIONS.values.index_with { |implementation| benchmark_samples(implementation) }
  end

  def run
    Benchmark.ips do |benchmark|
      benchmark.config(time: 10, warmup: 2)
      IMPLEMENTATIONS.each do |label, implementation|
        benchmark.report(label) { update_with(implementation) }
      end
      benchmark.compare!
    end
  end

  private

  def update_with(implementation)
    with_rollback do
      Samples::Metadata::BulkUpdateService.new(
        @project.namespace,
        metadata_payload(implementation),
        metadata_fields,
        @user,
        bulk_update_params(implementation)
      ).execute
    end
  end

  def with_rollback
    Sample.transaction(requires_new: true) do
      yield
      raise ActiveRecord::Rollback
    end
  end

  def bulk_update_params(implementation)
    { 'metadata_update_implementation' => implementation }
  end

  def metadata_payload(implementation)
    @counter += 1
    @sample_sets.fetch(implementation).to_h do |sample|
      [sample.id, benchmark_metadata]
    end
  end

  def benchmark_metadata
    deleted_field_names.index_with { '' }
                       .merge(updated_field_names.index_with { |field| "updated-#{field}-#{@counter}" })
                       .merge(analysis_updated_field_names.index_with { |field| "updated-#{field}-#{@counter}" })
                       .merge(created_field_names.index_with { |field| "created-#{field}-#{@counter}" })
                       .merge(unchanged_field_names.index_with { |field| initial_metadata[field] })
  end

  def benchmark_samples(implementation)
    Array.new(SAMPLE_COUNT) do |index|
      Sample.create!(
        project: @project,
        name: "#{implementation} bulk metadata benchmark #{index + 1} #{SecureRandom.uuid}",
        metadata: initial_metadata,
        metadata_provenance: initial_metadata_provenance
      )
    end
  end

  def metadata_fields
    deleted_field_names + updated_field_names + analysis_updated_field_names +
      created_field_names + unchanged_field_names
  end

  def initial_metadata
    deleted_field_names.index_with { 'delete me' }
                       .merge(updated_field_names.index_with { 'original value' })
                       .merge(analysis_updated_field_names.index_with { 'analysis value' })
                       .merge(unchanged_field_names.index_with { 'unchanged value' })
  end

  def initial_metadata_provenance
    initial_metadata.to_h do |field, _value|
      [field, metadata_provenance(field)]
    end
  end

  def metadata_provenance(field)
    if analysis_field?(field)
      { source: 'analysis', id: @analysis_id || 'benchmark-analysis', updated_at: Time.current.as_json }
    else
      { source: 'user', id: @user.id, updated_at: Time.current.as_json }
    end
  end

  def analysis_field?(field)
    deleted_field_names.include?(field) || analysis_updated_field_names.include?(field)
  end

  def deleted_field_names
    field_names('deleted', @metadata_counts[:deleted])
  end

  def updated_field_names
    field_names('updated', @metadata_counts[:updated])
  end

  def unchanged_field_names
    field_names('unchanged', @metadata_counts[:unchanged])
  end

  def analysis_updated_field_names
    field_names('analysis_updated', @metadata_counts[:analysis_updated])
  end

  def created_field_names
    field_names('created', @metadata_counts[:created])
  end

  def field_names(type, count)
    Array.new(count) { |index| "#{type}_field_#{index + 1}" }
  end
end

sample = Sample.find(ENV.fetch('SAMPLE_ID'))
user = User.find(ENV.fetch('USER_ID'))
analysis_id = ENV['ANALYSIS_ID'].presence
field_count = lambda do |name|
  count = Integer(ENV.fetch(name, 1))
  raise ArgumentError, "#{name} must be non-negative" if count.negative?

  count
end
metadata_counts = {
  deleted: field_count.call('DELETED_FIELD_COUNT'),
  updated: field_count.call('UPDATED_FIELD_COUNT'),
  unchanged: field_count.call('UNCHANGED_FIELD_COUNT'),
  created: field_count.call('CREATED_FIELD_COUNT'),
  analysis_updated: field_count.call('ANALYSIS_UPDATED_FIELD_COUNT')
}

Sample.transaction do
  BulkSampleMetadataUpdateBenchmark.new(sample, user, analysis_id, metadata_counts).run
  raise ActiveRecord::Rollback
end
