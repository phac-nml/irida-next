# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class AtomicUpdateServiceTest < ActiveSupport::TestCase
      def setup
        @analysis_id = 10
        @user = users(:john_doe)
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
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'analysis_id' => @analysis_id, 'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
      end

      test 'excludes matching values so their provenance is not rewritten' do
        freeze_time
        original_provenance = @atomic_sample.metadata_provenance['metadatafield1']

        metadata_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield3' => 'value3' },
            'analysis_id' => @analysis_id, 'metadata_update_implementation' => 'atomic' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield1'], metadata_changes[:unchanged]
        assert_equal original_provenance, @atomic_sample.metadata_provenance['metadatafield1']
        assert_equal(
          { 'source' => 'analysis', 'id' => @analysis_id, 'updated_at' => Time.current.as_json },
          @atomic_sample.metadata_provenance['metadatafield3']
        )
      end

      test 'adds user metadata with user provenance' do
        freeze_time

        metadata_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield3' => 'value3' }, 'metadata_update_implementation' => 'atomic' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield3'], metadata_changes[:added]
        assert_equal(
          { 'source' => 'user', 'id' => @user.id, 'updated_at' => Time.current.as_json },
          @atomic_sample.metadata_provenance['metadatafield3']
        )
      end

      test 'rewrites matching values when force_update is enabled' do
        freeze_time

        metadata_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield1' => 'value1' }, 'analysis_id' => @analysis_id,
            'force_update' => true, 'metadata_update_implementation' => 'atomic' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield1'], metadata_changes[:updated]
        assert_equal(
          { 'source' => 'analysis', 'id' => @analysis_id, 'updated_at' => Time.current.as_json },
          @atomic_sample.metadata_provenance['metadatafield1']
        )
      end

      test 'detects deleted fields from persisted metadata after their provenance is removed' do
        metadata_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield1' => '' }, 'analysis_id' => @analysis_id,
            'metadata_update_implementation' => 'atomic' }
        ).execute

        @atomic_sample.reload
        assert_equal ['metadatafield1'], metadata_changes[:deleted]
        assert_not @atomic_sample.metadata.key?('metadatafield1')
        assert_not @atomic_sample.metadata_provenance.key?('metadatafield1')
      end

      test 'does not let a user update analysis metadata but permits clearing it' do
        sample = samples(:sample34)

        changes = UpdateService.new(
          sample.project,
          sample,
          @user,
          { 'metadata' => { 'metadatafield1' => 'user value', 'metadatafield2' => '' },
            'metadata_update_implementation' => 'atomic' }
        ).execute

        sample.reload
        assert_equal ['metadatafield1'], changes[:not_updated]
        assert_equal ['metadatafield2'], changes[:deleted]
        assert_equal 'value1', sample.metadata['metadatafield1']
        assert_not sample.metadata.key?('metadatafield2')
      end

      test 'does not update a sample that does not belong to the supplied project' do
        sample = samples(:sample32)
        project = projects(:project30)

        changes = UpdateService.new(
          project,
          sample,
          @user,
          { 'metadata' => { 'metadatafield1' => 'new value' }, 'analysis_id' => @analysis_id,
            'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal ['metadatafield1'], changes[:not_updated]
        assert sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: sample.name,
                                                                                project_name: project.name)
        )
        assert_equal 'value1', sample.reload.metadata['metadatafield1']
      end
    end
  end
end
