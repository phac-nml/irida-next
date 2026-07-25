# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
    @project = projects(:project1)
    @project1 = projects(:project1)
    @project4 = projects(:project4)
    @fastq_regex = '^\\S+\\.f(ast)?q(\\.gz)?$'
    # project1 is under group_one
    # project4 is under subgroup_one_group_three -> group_three (deeply nested)
    Flipper.enable(:v2_samplesheet)
  end

  def teardown
    Sample.suppressed_turbo_broadcasts = false
  end

  test 'valid sample' do
    assert @sample.valid?
  end

  test 'valid sample with metadata' do
    @sample.metadata = {
      source: 'Human',
      province: 'MB',
      sex: 'Female'
    }
    assert @sample.valid?
  end

  test 'invalid sample with blank name' do
    @sample.name = nil
    assert_not @sample.valid?
    assert @sample.errors.added?(:name, :blank)
  end

  test 'invalid sample with short name' do
    @sample.name = 'a'
    assert_not @sample.valid?
    assert_not_nil @sample.errors[:name]
  end

  test 'invalid sample with long name' do
    @sample.name = 'a' * 256
    assert_not @sample.valid?
    assert_not_nil @sample.errors[:name]
  end

  test 'invalid sample with same name' do
    sample2 = samples(:sample2)
    @sample.name = sample2.name
    assert_not @sample.valid?
    assert_not_nil @sample.errors[:name]
  end

  test 'valid sample with metadata provenance' do
    @sample.metadata_provenance = {
      KEY1: {
        SOURCE: 'USER',
        SOURCE_ID: 1
      },
      KEY2: {
        SOURCE: 'ANALYSIS',
        SOURCE_ID: 2
      }
    }
    assert @sample.valid?
  end

  test '#destroy removes sample ' do
    assert_difference(-> { Sample.count } => -1) do
      @sample.destroy
    end
  end

  test '#destroy removes sample, then is restored' do
    assert_difference(-> { Sample.count } => -1) do
      @sample.destroy
    end

    assert_difference(-> { Sample.count } => +1) do
      Sample.restore(@sample.id, recursive: true)
    end
  end

  test 'update samples_counter in project' do
    Project.reset_counters(@project.id, :samples_count)

    @project.reload
    assert_equal @project.samples.count, @project.samples_count

    assert_difference(-> { @project.samples.count } => -1) do
      @sample.destroy
      @project.reload
      assert_equal @project.samples.count, @project.samples_count
    end

    assert_difference(-> { @project.samples.count } => +1) do
      Sample.restore(@sample.id, recursive: true)
      @project.reload
      assert_equal @project.samples.count, @project.samples_count
    end
  end

  test 'metadata_with_provenance for user source' do
    sample = samples(:sample32)
    user = users(:john_doe)
    expected_metadata_with_provenance = [{
      key: 'metadatafield1',
      value: 'value1',
      source: user.email,
      source_type: 'user',
      last_updated: DateTime.new(2000, 1, 1)
    }, {
      key: 'metadatafield2',
      value: 'value2',
      source: user.email,
      source_type: 'user',
      last_updated: DateTime.new(2000, 1, 1)
    }]
    assert_equal(expected_metadata_with_provenance, sample.metadata_with_provenance)
  end

  test 'metadata_with_provenance for analysis source' do
    sample = samples(:sample30)
    expected_metadata_with_provenance = [{
      key: 'metadatafield1',
      value: 'value1',
      source: "#{I18n.t('models.sample.analysis')} 1",
      source_type: 'analysis',
      last_updated: DateTime.new(2000, 1, 1)
    }, {
      key: 'metadatafield2',
      value: 'value2',
      source: "#{I18n.t('models.sample.analysis')} 1",
      source_type: 'analysis',
      last_updated: DateTime.new(2000, 1, 1)
    }]
    assert_equal(expected_metadata_with_provenance, sample.metadata_with_provenance)
  end

  test 'sample has a puid' do
    assert @sample.has_attribute?(:puid)
  end

  test '#model_prefix' do
    assert_equal 'SAM', Sample.model_prefix
  end

  test 'sample has an attachments_updated_at attribute' do
    assert @sample.has_attribute?(:attachments_updated_at)
  end

  test 'file_selector_fastq_files for forward' do
    # includes both forward PE and single fastq files
    sample_b = samples(:sampleB)

    attachment1 = attachments(:attachmentPEFWD3)
    attachment2 = attachments(:attachmentPEFWD2)
    attachment3 = attachments(:attachmentPEFWD1)
    attachment4 = attachments(:attachmentF)
    attachment5 = attachments(:attachmentE)
    attachment6 = attachments(:attachmentD)

    expected_attributes = [{
      filename: attachment1.file.filename.to_s,
      global_id: attachment1.to_global_id,
      id: attachment1.id,
      byte_size: attachment1.byte_size,
      created_at: attachment1.created_at,
      metadata: attachment1.metadata
    }, {
      filename: attachment2.file.filename.to_s,
      global_id: attachment2.to_global_id,
      id: attachment2.id,
      byte_size: attachment2.byte_size,
      created_at: attachment2.created_at,
      metadata: attachment2.metadata
    }, {
      filename: attachment3.file.filename.to_s,
      global_id: attachment3.to_global_id,
      id: attachment3.id,
      byte_size: attachment3.byte_size,
      created_at: attachment3.created_at,
      metadata: attachment3.metadata
    }, {
      filename: attachment4.file.filename.to_s,
      global_id: attachment4.to_global_id,
      id: attachment4.id,
      byte_size: attachment4.byte_size,
      created_at: attachment4.created_at,
      metadata: attachment4.metadata
    }, {
      filename: attachment5.file.filename.to_s,
      global_id: attachment5.to_global_id,
      id: attachment5.id,
      byte_size: attachment5.byte_size,
      created_at: attachment5.created_at,
      metadata: attachment5.metadata
    }, {
      filename: attachment6.file.filename.to_s,
      global_id: attachment6.to_global_id,
      id: attachment6.id,
      byte_size: attachment6.byte_size,
      created_at: attachment6.created_at,
      metadata: attachment6.metadata
    }]

    assert_equal expected_attributes, sample_b.file_selector_fastq_files('fastq_1', @fastq_regex, false)
  end

  test 'file_selector_fastq_files with pe_only' do
    # includes both forward PE and single fastq files
    sample_b = samples(:sampleB)

    attachment1 = attachments(:attachmentPEFWD3)
    attachment2 = attachments(:attachmentPEFWD2)
    attachment3 = attachments(:attachmentPEFWD1)

    expected_attributes = [{
      filename: attachment1.file.filename.to_s,
      global_id: attachment1.to_global_id,
      id: attachment1.id,
      byte_size: attachment1.byte_size,
      created_at: attachment1.created_at,
      metadata: attachment1.metadata
    }, {
      filename: attachment2.file.filename.to_s,
      global_id: attachment2.to_global_id,
      id: attachment2.id,
      byte_size: attachment2.byte_size,
      created_at: attachment2.created_at,
      metadata: attachment2.metadata
    }, {
      filename: attachment3.file.filename.to_s,
      global_id: attachment3.to_global_id,
      id: attachment3.id,
      byte_size: attachment3.byte_size,
      created_at: attachment3.created_at,
      metadata: attachment3.metadata
    }]

    assert_equal expected_attributes,
                 sample_b.file_selector_fastq_files('fastq_1', @fastq_regex, true)
  end

  test 'file_selector_fastq_files for reverse' do
    # only includes reverse PE files
    sample_b = samples(:sampleB)
    attachment1 = attachments(:attachmentPEREV3)
    attachment2 = attachments(:attachmentPEREV2)
    attachment3 = attachments(:attachmentPEREV1)
    expected_attributes = [{
      filename: attachment1.file.filename.to_s,
      global_id: attachment1.to_global_id,
      id: attachment1.id,
      byte_size: attachment1.byte_size,
      created_at: attachment1.created_at,
      metadata: attachment1.metadata
    }, {
      filename: attachment2.file.filename.to_s,
      global_id: attachment2.to_global_id,
      id: attachment2.id,
      byte_size: attachment2.byte_size,
      created_at: attachment2.created_at,
      metadata: attachment2.metadata
    }, {
      filename: attachment3.file.filename.to_s,
      global_id: attachment3.to_global_id,
      id: attachment3.id,
      byte_size: attachment3.byte_size,
      created_at: attachment3.created_at,
      metadata: attachment3.metadata
    }]

    assert_equal expected_attributes,
                 sample_b.file_selector_fastq_files('fastq_2', @fastq_regex, false)
  end

  test 'file_selector_fastq_files with no attachments' do
    sample2 = samples(:sample2)

    files = sample2.file_selector_fastq_files('fastq_1', @fastq_regex, false)

    assert files.empty?
  end

  test 'file_selector_other_files with pattern' do
    pattern = '^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$'
    expected_attachment = attachments(:gasclusteringAttachment)
    sample32 = samples(:sample32)
    expected_attributes = [{
      filename: expected_attachment.file.filename.to_s,
      global_id: expected_attachment.to_global_id,
      id: expected_attachment.id,
      byte_size: expected_attachment.byte_size,
      created_at: expected_attachment.created_at,
      metadata: expected_attachment.metadata
    }]

    assert_equal expected_attributes, sample32.file_selector_other_files(pattern)
  end

  test 'file_selector_other_files with no pattern' do
    sample32 = samples(:sample32)
    attachment1 = attachments(:sample32JsonAttachment)
    attachment2 = attachments(:gasclusteringAttachment)

    expected_attributes = [{
      filename: attachment1.file.filename.to_s,
      global_id: attachment1.to_global_id,
      id: attachment1.id,
      byte_size: attachment1.byte_size,
      created_at: attachment1.created_at,
      metadata: attachment1.metadata
    }, {
      filename: attachment2.file.filename.to_s,
      global_id: attachment2.to_global_id,
      id: attachment2.id,
      byte_size: attachment2.byte_size,
      created_at: attachment2.created_at,
      metadata: attachment2.metadata
    }]
    assert_equal expected_attributes, sample32.file_selector_other_files(nil)
  end

  test 'field? returns true when metadata has field' do
    @sample.metadata = { test_field: 'value' }
    assert @sample.field?('test_field')
  end

  test 'field? returns false when metadata does not have field' do
    @sample.metadata = { other_field: 'value' }
    assert_not @sample.field?('test_field')
  end

  test 'updatable_field? returns true when field not in metadata_provenance' do
    @sample.metadata = { test_field: 'value' }
    assert @sample.updatable_field?('test_field')
  end

  test 'updatable_field? returns true when field source is user' do
    @sample.metadata = { test_field: 'value' }
    @sample.metadata_provenance = { test_field: { source: 'user' } }
    assert @sample.updatable_field?('test_field')
  end

  test 'updatable_field? returns false when field source is not user' do
    @sample.metadata = { test_field: 'value' }
    @sample.metadata_provenance = { test_field: { source: 'analysis' } }
    assert_not @sample.updatable_field?('test_field')
  end

  def count_broadcasts_for
    broadcast_calls = []
    original_method = Project.instance_method(:broadcast_refresh_later_to)

    Project.class_eval do
      define_method(:broadcast_refresh_later_to) do |streamable, stream_name|
        broadcast_calls << [streamable, stream_name]
        nil # Don't actually broadcast in tests
      end
    end

    yield
    broadcast_calls
  ensure
    # Restore original method
    Project.class_eval do
      define_method(:broadcast_refresh_later_to, original_method)
    end
  end

  test 'broadcasts to project and ancestors on sample create when flag enabled' do
    project = @project1
    ancestors = project.namespace.parent.self_and_ancestors

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'New Sample Test', project: project)
    end

    # Verify broadcasts to project + ancestors
    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
    assert_equal :samples, broadcast_calls.first[1]
  end

  test 'broadcasts to project and ancestors on sample update when flag enabled' do
    sample = samples(:sample1)
    project = sample.project
    ancestors = project.namespace.parent.self_and_ancestors

    broadcast_calls = count_broadcasts_for do
      sample.update!(name: 'Updated Sample Name')
    end

    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'broadcasts to project and ancestors on sample destroy when flag enabled' do
    sample = samples(:sample1)
    project = sample.project
    ancestors = project.namespace.parent.self_and_ancestors

    broadcast_calls = count_broadcasts_for do
      sample.destroy
    end

    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'broadcasts to project and ancestors on sample restore when flag enabled' do
    sample = samples(:sample1)
    project = sample.project
    ancestors = project.namespace.parent.self_and_ancestors

    # Destroy and restore to get a restored sample
    sample.destroy
    sample_id = sample.id
    Sample.restore(sample_id, recursive: true)
    restored_sample = Sample.find(sample_id)

    # Test the broadcast method directly since Sample.restore doesn't trigger after_commit in tests
    broadcast_calls = count_broadcasts_for do
      restored_sample.send(:broadcast_refresh_later_to_samples_table)
    end

    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'broadcasts to both old and new projects when sample transferred with flag enabled' do
    sample = samples(:sample1)
    old_project = sample.project
    new_project = @project4
    old_ancestors = old_project.namespace.parent.self_and_ancestors
    new_ancestors = new_project.namespace.parent.self_and_ancestors

    broadcast_calls = count_broadcasts_for do
      sample.update!(project: new_project)
    end

    # Expected: 2 projects + old_ancestors + new_ancestors
    expected_count = 2 + old_ancestors.count + new_ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'handles sample transfer when old project is nil' do
    # This tests the edge case in the code: previous_changes['project_id'][0].nil?
    project = @project1
    ancestors = project.namespace.parent.self_and_ancestors

    # Creating a new sample (no previous project_id)
    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'New Sample No Old Project', project: project)
    end

    # Expected: 1 project + ancestors (no old project to broadcast to)
    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'no broadcasts when Sample.suppressed_turbo_broadcasts is true' do
    Sample.suppressed_turbo_broadcasts = true
    project = @project1

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'Suppressed Sample', project: project)
    end

    # No broadcasts should occur
    assert_equal 0, broadcast_calls.count
  ensure
    Sample.suppressed_turbo_broadcasts = false
  end

  test 'broadcasts resume when suppression is removed' do
    project = @project1
    ancestors = project.namespace.parent.self_and_ancestors

    # First operation with suppression
    Sample.suppressed_turbo_broadcasts = true
    broadcast_calls_suppressed = count_broadcasts_for do
      Sample.create!(name: 'Suppressed Sample 1', project: project)
    end

    assert_equal 0, broadcast_calls_suppressed.count

    # Remove suppression
    Sample.suppressed_turbo_broadcasts = false

    # Second operation should broadcast normally
    broadcast_calls_resumed = count_broadcasts_for do
      Sample.create!(name: 'Resumed Sample 2', project: project)
    end

    # Verify broadcasts resumed (project + ancestors)
    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls_resumed.count
  ensure
    Sample.suppressed_turbo_broadcasts = false
  end

  test 'broadcasts to all ancestors in deeply nested namespace hierarchy when flag enabled' do
    # Use project4 which is under subgroup_one_group_three -> group_three
    project = @project4
    ancestors = project.namespace.parent.self_and_ancestors

    # Verify we have a deep hierarchy (at least 2 ancestors)
    assert ancestors.count >= 2, 'Test requires deeply nested namespace'

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'Deep Nested Sample', project: project)
    end

    # Expected: 1 project + all ancestors
    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'ancestor broadcasts include correct stream name and arguments' do
    project = @project1
    ancestors = project.namespace.parent.self_and_ancestors

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'Stream Verification Sample', project: project)
    end

    # Verify all broadcasts have the correct stream name (:samples)
    broadcast_calls.each do |call|
      assert_equal :samples, call[1], 'All broadcasts should use :samples stream name'
    end

    # Verify first broadcast is to project
    assert_equal project, broadcast_calls.first[0]

    # Verify we have the expected number of broadcasts
    expected_count = 1 + ancestors.count
    assert_equal expected_count, broadcast_calls.count
  end

  test 'creating a sample propagates samples_count to project and group ancestors' do
    # Hierarchy: group_twelve -> subgroup_twelve_a -> subgroup_twelve_a_a -> project31
    project31 = projects(:project31)
    subgroup12aa = groups(:subgroup_twelve_a_a)
    subgroup12a = groups(:subgroup_twelve_a)
    group12 = groups(:group_twelve)

    # Reset counts
    [project31.namespace, subgroup12aa, subgroup12a, group12].each do |ns|
      ns.update(samples_count: 0)
    end

    assert_difference(-> { project31.reload.samples_count } => 1,
                      -> { subgroup12aa.reload.samples_count } => 1,
                      -> { subgroup12a.reload.samples_count } => 1,
                      -> { group12.reload.samples_count } => 1) do
      Sample.create!(name: 'Test Sample Create', project: project31)
    end
  end

  test 'deleting a sample propagates samples_count decrement to project and group ancestors' do
    # Hierarchy: group_twelve -> subgroup_twelve_a -> subgroup_twelve_a_a -> project31
    project31 = projects(:project31)
    subgroup12aa = groups(:subgroup_twelve_a_a)
    subgroup12a = groups(:subgroup_twelve_a)
    group12 = groups(:group_twelve)

    # Create a sample first
    sample = Sample.create!(name: 'Test Sample Delete', project: project31)

    # Reload all to get current counts
    project31.reload
    subgroup12aa.reload
    subgroup12a.reload
    group12.reload

    # Verify sample was created and counts incremented
    assert project31.samples_count.positive?
    assert subgroup12a.samples_count.positive?
    assert subgroup12aa.samples_count.positive?
    assert group12.samples_count.positive?

    # Now delete and verify counts decrement
    assert_difference(-> { project31.reload.samples_count } => -1,
                      -> { subgroup12aa.reload.samples_count } => -1,
                      -> { subgroup12a.reload.samples_count } => -1,
                      -> { group12.reload.samples_count } => -1) do
      sample.destroy
    end
  end

  test 'restoring a deleted sample propagates samples_count increment to project and group ancestors' do
    # Hierarchy: group_twelve -> subgroup_twelve_a -> subgroup_twelve_a_a -> project31
    project31 = projects(:project31)
    subgroup12aa = groups(:subgroup_twelve_a_a)
    subgroup12a = groups(:subgroup_twelve_a)
    group12 = groups(:group_twelve)

    # Create a sample
    sample = Sample.create!(name: 'Test Sample Restore', project: project31)
    sample_id = sample.id

    # Reload to get accurate counts after creation
    project31.reload
    subgroup12aa.reload
    subgroup12a.reload
    group12.reload

    project_count_after_create = project31.samples_count
    subgroup12a_count_after_create = subgroup12a.samples_count
    subgroup12aa_count_after_create = subgroup12aa.samples_count
    group12_count_after_create = group12.samples_count

    # Delete the sample
    sample.destroy
    project31.reload
    subgroup12aa.reload
    subgroup12a.reload
    group12.reload

    # Verify counts decremented after delete
    assert_equal project_count_after_create - 1, project31.samples_count
    assert_equal subgroup12a_count_after_create - 1, subgroup12a.samples_count
    assert_equal subgroup12aa_count_after_create - 1, subgroup12aa.samples_count
    assert_equal group12_count_after_create - 1, group12.samples_count

    # Restore the sample and verify counts increment
    assert_difference(-> { project31.reload.samples_count } => 1,
                      -> { subgroup12aa.reload.samples_count } => 1,
                      -> { subgroup12a.reload.samples_count } => 1,
                      -> { group12.reload.samples_count } => 1) do
      Sample.restore(sample_id, recursive: true)
    end
  end

  test 'transferring a sample between projects in different hierarchies propagates counts correctly' do
    # Transfer from project31 (group_twelve -> subgroup_twelve_a -> subgroup_twelve_a_a)
    # to project1 (group_one)
    project31 = projects(:project31)
    project1 = projects(:project1)
    subgroup12aa = groups(:subgroup_twelve_a_a)
    subgroup12a = groups(:subgroup_twelve_a)
    group12 = groups(:group_twelve)
    group_one = groups(:group_one)

    # Create sample in project31
    sample = Sample.create!(name: 'Test Sample Transfer', project: project31)

    # Reload all to get current counts
    project31.reload
    project1.reload
    subgroup12aa.reload
    subgroup12a.reload
    group12.reload
    group_one.reload

    # Store counts before transfer
    project31_count_before = project31.samples_count
    project1_count_before = project1.samples_count
    group12_count_before = group12.samples_count
    group_one_count_before = group_one.samples_count

    # Transfer sample to project1
    sample.update(project: project1)

    # Verify old hierarchy decremented
    assert_equal project31_count_before - 1, project31.reload.samples_count
    assert_equal group12_count_before - 1, group12.reload.samples_count

    # Verify new hierarchy incremented
    assert_equal project1_count_before + 1, project1.reload.samples_count
    assert_equal group_one_count_before + 1, group_one.reload.samples_count
  end

  test 'transferring a sample within same project hierarchy does not change ancestor counts' do
    # Both projects under group_one, so transfers should only move count within same hierarchy
    project1 = projects(:project1)
    project5 = projects(:project5)
    group_one = groups(:group_one)

    # Create sample in project1
    sample = Sample.create!(name: 'Test Sample Transfer Within', project: project1)

    project1.reload
    project5.reload
    group_one.reload

    # Store counts before transfer
    group_one_count_before = group_one.samples_count

    # Transfer sample to project5 (same group)
    sample.update(project: project5)

    # Group one count should remain same (decrement from project1, increment to project5)
    assert_equal group_one_count_before, group_one.reload.samples_count

    # Project counts should be updated correctly
    assert project1.reload.samples_count < (project1.samples.count + 1)
    assert project5.reload.samples_count > (project5.samples.count - 1)
  end

  test 'multiple samples creation and deletion maintains correct hierarchy counts' do
    # Test with multiple samples to ensure counts stay accurate
    project31 = projects(:project31)
    subgroup12a = groups(:subgroup_twelve_a)
    group12 = groups(:group_twelve)

    # NOTE: project31 already has 2 samples in the fixture (sample34, sample35)
    initial_project_count = project31.samples_count
    initial_subgroup_count = subgroup12a.samples_count
    initial_group_count = group12.samples_count

    # Create 3 additional samples
    samples = []
    3.times do |i|
      samples << Sample.create!(name: "Multi Sample #{i}", project: project31)
    end

    project31.reload
    subgroup12a.reload
    group12.reload

    # Verify all 3 new samples were counted
    assert_equal initial_project_count + 3, project31.samples_count
    assert_equal initial_subgroup_count + 3, subgroup12a.samples_count
    assert_equal initial_group_count + 3, group12.samples_count

    # Delete 2 of the new samples
    samples[0].destroy
    samples[1].destroy

    # Verify counts decremented by 2
    assert_equal initial_project_count + 1, project31.reload.samples_count
    assert_equal initial_subgroup_count + 1, subgroup12a.reload.samples_count
    assert_equal initial_group_count + 1, group12.reload.samples_count

    # Restore one
    Sample.restore(samples[0].id, recursive: true)

    # Verify count incremented by 1 again
    assert_equal initial_project_count + 2, project31.reload.samples_count
    assert_equal initial_subgroup_count + 2, subgroup12a.reload.samples_count
    assert_equal initial_group_count + 2, group12.reload.samples_count
  end
end
