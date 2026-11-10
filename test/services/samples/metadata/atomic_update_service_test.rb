# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class AtomicUpdateServiceTest < ActiveSupport::TestCase
      def setup
        @analysis_id = 10
        @legacy_sample = samples(:sample33)
        @atomic_sample = samples(:sample32)
      end

      test 'matches the existing service for analysis additions, updates, and deletions' do
        freeze_time
        metadata = {
          'metadatafield1' => 'newvalue1',
          'metadatafield2' => '',
          'metadatafield3' => 'value3'
        }

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          users(:john_doe),
          { 'metadata' => metadata, 'analysis_id' => @analysis_id, include_activity: false, 'force_update' => false }
        ).execute
        atomic_changes = AtomicUpdateService.new(@atomic_sample, @analysis_id, metadata).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
      end

      test 'excludes matching values so their provenance is not rewritten' do
        freeze_time
        original_provenance = @atomic_sample.metadata_provenance['metadatafield1']

        metadata_changes = AtomicUpdateService.new(
          @atomic_sample,
          @analysis_id,
          { 'metadatafield1' => 'value1', 'metadatafield3' => 'value3' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield1'], metadata_changes[:unchanged]
        assert_equal original_provenance, @atomic_sample.metadata_provenance['metadatafield1']
        assert_equal(
          { 'source' => 'analysis', 'id' => @analysis_id, 'updated_at' => Time.current.as_json },
          @atomic_sample.metadata_provenance['metadatafield3']
        )
      end

      test 'detects deleted fields from persisted metadata after their provenance is removed' do
        metadata_changes = AtomicUpdateService.new(
          @atomic_sample,
          @analysis_id,
          { 'metadatafield1' => '' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield1'], metadata_changes[:deleted]
        assert_not @atomic_sample.metadata.key?('metadatafield1')
        assert_not @atomic_sample.metadata_provenance.key?('metadatafield1')
      end

      test 'does not let a user update analysis metadata but permits clearing it' do
        sample = samples(:sample34)

        changes = AtomicUpdateService.new(
          sample,
          nil,
          { 'metadatafield1' => 'user value', 'metadatafield2' => '' }
        ).execute

        sample.reload
        assert_equal ['metadatafield1'], changes[:not_updated]
        assert_equal ['metadatafield2'], changes[:deleted]
        assert_equal 'value1', sample.metadata['metadatafield1']
        assert_not sample.metadata.key?('metadatafield2')
      end
    end
  end
end
