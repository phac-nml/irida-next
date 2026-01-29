# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
    @project = projects(:project1)
    @project1 = projects(:project1)
    @project4 = projects(:project4)
    # project1 is under group_one
    # project4 is under subgroup_one_group_three -> group_three (deeply nested)
    Flipper.enable(:samples_refresh_notice)
    Flipper.enable(:deferred_samplesheet)
  end

  def teardown
    Flipper.disable(:samples_refresh_notice)
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

    attachment1 = attachments(:attachmentF)
    attachment2 = attachments(:attachmentPEFWD3)
    attachment3 = attachments(:attachmentE)
    attachment4 = attachments(:attachmentPEFWD2)
    attachment5 = attachments(:attachmentD)
    attachment6 = attachments(:attachmentPEFWD1)

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

    assert_equal expected_attributes, sample_b.file_selector_fastq_files('fastq_1')
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

    assert_equal expected_attributes, sample_b.file_selector_fastq_files('fastq_2')
  end

  test 'file_selector_fastq_files with no attachments' do
    sample2 = samples(:sample2)

    files = sample2.file_selector_fastq_files('fastq_1')

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

  test 'most_recent_fastq_files with both PE and non-PE attached' do
    # PE attachments prioritized over non-PE fastq files
    sample_b = samples(:sampleB)
    actual_most_recent_attachment = attachments(:attachmentF)
    most_recent_pe_fwd = attachments(:attachmentPEFWD3)
    most_recent_pe_rev = attachments(:attachmentPEREV3)

    expected_attributes = {
      'fastq_1' => {
        filename: most_recent_pe_fwd.file.filename,
        global_id: most_recent_pe_fwd.to_global_id,
        id: most_recent_pe_fwd.id
      },
      'fastq_2' => {
        filename: most_recent_pe_rev.file.filename,
        global_id: most_recent_pe_rev.to_global_id,
        id: most_recent_pe_rev.id
      }
    }

    # check most recent file attached is not PE
    assert_equal actual_most_recent_attachment.file.filename, sample_b.attachments.last.file.filename
    assert_equal expected_attributes, sample_b.most_recent_fastq_files
  end

  test 'most_recent_fastq_files with no PE' do
    sample = samples(:sample1)
    expected_attachment = attachments(:attachment2)
    expected_attributes = {
      'fastq_1' => {
        filename: expected_attachment.file.filename,
        global_id: expected_attachment.to_global_id,
        id: expected_attachment.id
      },
      'fastq_2' => {}
    }

    assert_equal expected_attributes, sample.most_recent_fastq_files
  end

  test 'most_recent_fastq_files with attachments but no fastq' do
    sample = samples(:sample3)
    assert_equal 1, sample.attachments.count
    assert_equal 'fasta', sample.attachments.first.metadata['format']
    expected_attributes = {
      'fastq_1' => {},
      'fastq_2' => {}
    }
    assert_equal expected_attributes, sample.most_recent_fastq_files
  end

  test 'most_recent_fastq_files with no attachments' do
    sample = samples(:sample2)
    assert_equal 0, sample.attachments.count
    expected_attributes = {
      'fastq_1' => {},
      'fastq_2' => {}
    }
    assert_equal expected_attributes, sample.most_recent_fastq_files
  end

  test 'most_recent_other_file with pattern' do
    pattern = '^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$'
    expected_attachment = attachments(:gasclusteringAttachment)
    sample32 = samples(:sample32)
    expected_attributes = {
      filename: expected_attachment.file.filename,
      global_id: expected_attachment.to_global_id,
      id: expected_attachment.id
    }

    assert_equal expected_attributes, sample32.most_recent_other_file(true, pattern)
  end

  test 'most_recent_other_file with no attachments' do
    sample = samples(:sample2)
    assert sample.most_recent_other_file(true, nil).empty?
  end

  test 'most_recent_other_file with false autopopulate' do
    sample = samples(:sample32)
    assert sample.most_recent_other_file(false, nil).empty?
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

  test 'broadcasts only to project on sample create when flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    project = @project1

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'New Sample No Flag', project: project)
    end

    # Only 1 broadcast (to project only, no ancestors)
    assert_equal 1, broadcast_calls.count
  end

  test 'broadcasts only to project on sample update when flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    sample = samples(:sample1)

    broadcast_calls = count_broadcasts_for do
      sample.update!(name: 'Updated Without Flag')
    end

    assert_equal 1, broadcast_calls.count
  end

  test 'broadcasts only to project on sample destroy when flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    sample = samples(:sample2)

    broadcast_calls = count_broadcasts_for do
      sample.destroy
    end

    assert_equal 1, broadcast_calls.count
  end

  test 'broadcasts only to project on sample restore when flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    sample = samples(:sample2)

    # Destroy and restore to get a restored sample
    sample.destroy
    sample_id = sample.id
    Sample.restore(sample_id, recursive: true)
    restored_sample = Sample.find(sample_id)

    # Test the broadcast method directly since Sample.restore doesn't trigger after_commit in tests
    broadcast_calls = count_broadcasts_for do
      restored_sample.send(:broadcast_refresh_later_to_samples_table)
    end

    assert_equal 1, broadcast_calls.count
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

  test 'broadcasts to both old and new projects when sample transferred with flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    sample = samples(:sample2)

    broadcast_calls = count_broadcasts_for do
      sample.update!(project: @project4)
    end

    # Expected: 2 broadcasts (old project + new project), no ancestors
    assert_equal 2, broadcast_calls.count
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

  test 'broadcasts only to project in deeply nested namespace when flag disabled' do
    Flipper.disable(:samples_refresh_notice)
    project = @project4
    ancestors = project.namespace.parent.self_and_ancestors

    # Verify we have a deep hierarchy
    assert ancestors.count >= 2, 'Test requires deeply nested namespace'

    broadcast_calls = count_broadcasts_for do
      Sample.create!(name: 'Deep Nested No Flag', project: project)
    end

    # Expected: 1 broadcast (project only, no ancestors)
    assert_equal 1, broadcast_calls.count
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
end
