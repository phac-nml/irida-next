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
        @atomic_sample.create_logidze_snapshot!
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
          { 'metadata' => metadata, 'analysis_id' => @analysis_id, include_activity: false, 'force_update' => false,
            'metadata_update_implementation' => 'original' }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'analysis_id' => @analysis_id,
            'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
      end

      test 'matches the existing service for a no-op metadata update' do
        freeze_time
        metadata = { 'metadatafield1' => 'value1' }
        @atomic_sample.reload
        legacy_log_data = @legacy_sample.log_data
        legacy_updated_at = @legacy_sample.updated_at
        atomic_log_data = @atomic_sample.log_data
        atomic_updated_at = @atomic_sample.updated_at

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, include_activity: false, 'metadata_update_implementation' => 'original' }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, include_activity: false, 'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
        assert_equal legacy_log_data, @legacy_sample.log_data
        assert_equal legacy_updated_at, @legacy_sample.updated_at
        assert_equal atomic_log_data, @atomic_sample.log_data
        assert_equal atomic_updated_at, @atomic_sample.updated_at
      end

      test 'leaves the sample clean and synced to the persisted row after an atomic update' do
        original_updated_at = @atomic_sample.updated_at

        UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield3' => 'value3' }, 'metadata_update_implementation' => 'atomic',
            include_activity: false }
        ).execute

        persisted_sample = Sample.find(@atomic_sample.id)
        assert_not @atomic_sample.changed?
        assert_equal persisted_sample.metadata, @atomic_sample.metadata
        assert_equal persisted_sample.metadata_provenance, @atomic_sample.metadata_provenance
        assert_equal persisted_sample.updated_at, @atomic_sample.updated_at
        assert_not_equal original_updated_at, @atomic_sample.updated_at
      end

      test 'matches the existing service by raising RecordNotFound when the sample row no longer exists' do
        @legacy_sample.reload
        @atomic_sample.reload
        Sample.where(id: [@legacy_sample.id, @atomic_sample.id]).delete_all

        metadata = { 'metadatafield1' => 'newvalue', 'metadatafield3' => 'value3' }

        assert_raises(ActiveRecord::RecordNotFound) do
          UpdateService.new(
            @legacy_sample.project,
            @legacy_sample,
            @user,
            { 'metadata' => metadata, 'metadata_update_implementation' => 'original', include_activity: false }
          ).execute
        end

        assert_raises(ActiveRecord::RecordNotFound) do
          UpdateService.new(
            @atomic_sample.project,
            @atomic_sample,
            @user,
            { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
          ).execute
        end
      end

      test 'matches the existing service when updating a soft-deleted sample' do
        freeze_time
        @legacy_sample.reload
        @atomic_sample.reload
        @legacy_sample.destroy
        @atomic_sample.destroy

        metadata = { 'metadatafield1' => 'newvalue', 'metadatafield3' => 'value3' }

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original', include_activity: false }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
        ).execute

        assert_equal legacy_changes, atomic_changes

        legacy_reloaded = Sample.unscoped.find(@legacy_sample.id)
        atomic_reloaded = Sample.unscoped.find(@atomic_sample.id)
        assert_equal legacy_reloaded.metadata, atomic_reloaded.metadata
        assert_equal legacy_reloaded.metadata_provenance, atomic_reloaded.metadata_provenance
        # The soft-deleted row is updated in place; neither implementation clears deleted_at.
        assert_not_nil atomic_reloaded.deleted_at
      end

      test 'matches the existing service when a user updates one analysis-owned field' do
        freeze_time
        analysis_metadata = { 'metadatafield1' => 'analysis value' }
        [@legacy_sample, @atomic_sample].zip(%w[original atomic]).each do |sample, implementation|
          UpdateService.new(
            sample.project,
            sample,
            @user,
            { 'metadata' => analysis_metadata, 'analysis_id' => @analysis_id,
              'metadata_update_implementation' => implementation, include_activity: false }
          ).execute
        end

        user_metadata = { 'metadatafield1' => 'user value' }
        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => user_metadata, 'metadata_update_implementation' => 'original', include_activity: false }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => user_metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
        ).execute

        assert_equal legacy_changes, atomic_changes
        assert_equal ['metadatafield1'], atomic_changes[:not_updated]

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
        assert_equal 'analysis value', @atomic_sample.metadata['metadatafield1']
      end

      test 'normalizes distinct raw keys that collapse to the same key, with last-value-wins semantics' do
        freeze_time
        # 'MetadataField1' and ' metadatafield1 ' both normalize (downcase + strip_whitespaces) to
        # 'metadatafield1', so the payload contains two distinct raw keys targeting the same field.
        # Both implementations normalize the payload into a plain Hash (via normalized_metadata)
        # before classifying changes, so duplicate normalized keys collapse the same way for both:
        # the later raw key wins, and the field is reported only once.
        metadata = {
          'MetadataField1' => 'newvalue_a',
          ' metadatafield1 ' => 'newvalue_b'
        }

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original' }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload

        assert_equal 'newvalue_b', @legacy_sample.metadata['metadatafield1']
        assert_equal 'newvalue_b', @atomic_sample.metadata['metadatafield1']
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
        assert_equal ['metadatafield1'], legacy_changes[:updated]
        assert_equal ['metadatafield1'], atomic_changes[:updated]
      end

      test 'normalizes metadata when the payload is ActionController::Parameters, not a plain Hash' do
        freeze_time
        # Regression test: controllers (e.g. Projects::Samples::Metadata::DeletionsController) pass
        # permitted ActionController::Parameters as the metadata payload, not a plain Hash.
        # normalized_metadata must handle both the same way (ActionController::Parameters does not
        # implement filter_map, unlike Hash).
        metadata = ActionController::Parameters.new(
          'metadatafield1' => 'newvalue1',
          'metadatafield3' => 'value3'
        ).permit!

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original' }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic' }
        ).execute

        assert_equal legacy_changes, atomic_changes

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
        assert_equal 'newvalue1', @legacy_sample.metadata['metadatafield1']
        assert_equal 'newvalue1', @atomic_sample.metadata['metadatafield1']
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

      test 'broadcasts a refresh after an atomic update commits' do
        ActiveRecord.expects(:after_all_transactions_commit).yields
        Project.any_instance.expects(:broadcast_refresh_later_to_samples_table).once

        UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => { 'metadatafield3' => 'value3' }, 'metadata_update_implementation' => 'atomic' }
        ).execute
      end

      test 'does not schedule a broadcast when atomic updates suppress Turbo broadcasts' do
        ActiveRecord.expects(:after_all_transactions_commit).never

        Sample.suppressing_turbo_broadcasts do
          UpdateService.new(
            @atomic_sample.project,
            @atomic_sample,
            @user,
            { 'metadata' => { 'metadatafield3' => 'value3' }, 'metadata_update_implementation' => 'atomic' }
          ).execute
        end
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

      test 'matches the existing service when deleting a metadata key that does not exist' do
        metadata = { 'metadatafield3' => '' }
        Project.any_instance.expects(:broadcast_refresh_later_to_samples_table).never
        Namespaces::ProjectNamespace.any_instance.expects(:update_metadata_summary_by_update_service).never

        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original', include_activity: false }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
        ).execute

        assert_equal legacy_changes, atomic_changes
        assert_equal ['metadatafield3'], legacy_changes[:not_found]

        @legacy_sample.reload
        @atomic_sample.reload
        assert_equal @legacy_sample.metadata, @atomic_sample.metadata
        assert_equal @legacy_sample.metadata_provenance, @atomic_sample.metadata_provenance
      end

      test 'matches the existing service when deleting a key from a stale sample instance' do
        [@legacy_sample, @atomic_sample].each do |sample|
          Sample.find(sample.id).update!(metadata: {}, metadata_provenance: {})
        end

        metadata = { 'metadatafield1' => '' }
        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original', include_activity: false }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
        ).execute

        assert_equal legacy_changes, atomic_changes
      end

      test 'uses persisted provenance when updating a stale sample instance' do
        freeze_time
        persisted_metadata = { 'metadatafield1' => 'analysis value' }
        persisted_provenance = {
          'metadatafield1' => {
            'source' => 'analysis',
            'id' => @analysis_id,
            'updated_at' => Time.current.as_json
          }
        }
        [@legacy_sample, @atomic_sample].each do |sample|
          Sample.find(sample.id).update!(
            metadata: persisted_metadata,
            metadata_provenance: persisted_provenance
          )
        end

        metadata = { 'metadatafield1' => 'user value' }
        legacy_changes = UpdateService.new(
          @legacy_sample.project,
          @legacy_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'original', include_activity: false }
        ).execute
        atomic_changes = UpdateService.new(
          @atomic_sample.project,
          @atomic_sample,
          @user,
          { 'metadata' => metadata, 'metadata_update_implementation' => 'atomic', include_activity: false }
        ).execute

        assert_equal legacy_changes, atomic_changes
        assert_equal ['metadatafield1'], legacy_changes[:not_updated]
      end

      test 'does not let a user update analysis metadata but permits clearing it' do
        sample = samples(:sample34)
        sample.create_logidze_snapshot!

        changes = UpdateService.new(
          sample.project,
          sample,
          @user,
          { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => '' },
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
