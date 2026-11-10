# frozen_string_literal: true

require_relative '../config/environment'
require 'benchmark/ips'

# Compares persisted analysis metadata updates without retaining benchmark records.
class AtomicSampleMetadataUpdateBenchmark # rubocop:disable Metrics/ClassLength
  attr_reader :atomic_sample, :cte_atomic_sample, :legacy_sample

  def initialize(sample, user, analysis_id, metadata_counts)
    @sample = sample
    @user = user
    @analysis_id = analysis_id
    @metadata_counts = metadata_counts
    @counter = 0
    @legacy_sample = benchmark_sample('legacy')
    @atomic_sample = benchmark_sample('atomic')
    @cte_atomic_sample = benchmark_sample('cte atomic')
  end

  def run
    Benchmark.ips do |benchmark|
      benchmark.config(time: 10, warmup: 2)
      benchmark.report('existing update service') { update_with_existing_service }
      benchmark.report('atomic update service') { update_with_atomic_service }
      benchmark.report('CTE atomic update service') { update_with_cte_atomic_service }
      benchmark.compare!
    end
  end

  private

  def update_with_existing_service
    with_rollback(legacy_sample) do |sample|
      Samples::Metadata::UpdateService.new(
        sample.project,
        sample,
        @user,
        { 'metadata' => benchmark_metadata, 'analysis_id' => @analysis_id, include_activity: false }
      ).execute
    end
  end

  def update_with_atomic_service
    with_rollback(atomic_sample) do |sample|
      Samples::Metadata::AtomicUpdateService.new(
        sample.project,
        sample,
        @user,
        { 'metadata' => benchmark_metadata, 'analysis_id' => @analysis_id }
      ).execute
    end
  end

  def update_with_cte_atomic_service
    with_rollback(cte_atomic_sample) do |sample|
      Samples::Metadata::CteAtomicUpdateService.new(
        sample.project,
        sample,
        @user,
        { 'metadata' => benchmark_metadata, 'analysis_id' => @analysis_id }
      ).execute
    end
  end

  def with_rollback(sample)
    sample.reload
    Sample.transaction(requires_new: true) do
      yield sample
      raise ActiveRecord::Rollback
    end
  end

  def benchmark_metadata
    @counter += 1
    deleted_field_names.index_with { '' }
                       .merge(updated_field_names.index_with { |field| "updated-#{field}-#{@counter}" })
                       .merge(analysis_updated_field_names.index_with { |field| "updated-#{field}-#{@counter}" })
                       .merge(created_field_names.index_with { |field| "created-#{field}-#{@counter}" })
                       .merge(unchanged_field_names.index_with { |field| initial_metadata[field] })
  end

  def benchmark_sample(implementation)
    Sample.create!(
      project: @sample.project,
      name: "#{@sample.name} #{implementation} benchmark #{SecureRandom.uuid}",
      metadata: initial_metadata,
      metadata_provenance: initial_metadata_provenance
    )
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
  AtomicSampleMetadataUpdateBenchmark.new(sample, user, analysis_id, metadata_counts).run
  raise ActiveRecord::Rollback
end
