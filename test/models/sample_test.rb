# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
    @project = projects(:project1)
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

  test 'sort_files for pe' do
    sample_b = samples(:sampleB)

    files = sample_b.sort_files

    assert_equal 3, files[:singles].count
    assert_equal 3, files[:pe_forward].count
    assert_equal 3, files[:pe_reverse].count
  end

  test 'sorted_files with files including pe' do
    sample_b = samples(:sampleB)

    files = sample_b.sort_files

    assert_equal 3, files[:singles].count
    assert_equal 3, files[:pe_forward].count
    assert_equal 3, files[:pe_reverse].count
  end

  test 'ordering by sort_files' do
    sample_b = samples(:sampleB)
    attachmentPEFWD1 = attachments(:attachmentPEFWD1)
    attachmentPEREV1 = attachments(:attachmentPEREV1)
    attachmentPEFWD2 = attachments(:attachmentPEFWD2)
    attachmentPEREV2 = attachments(:attachmentPEREV2)
    attachmentPEFWD3 = attachments(:attachmentPEFWD3)
    attachmentPEREV3 = attachments(:attachmentPEREV3)
    attachmentD = attachments(:attachmentD)
    attachmentE = attachments(:attachmentE)
    attachmentF = attachments(:attachmentF)

    # ["#{attachment.file.filename} (#{attachment.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
    #  attachment.to_global_id,
    #  { 'data-puid': attachment.puid }]

    files = sample_b.sort_files
    expected_singles_files =
    [["#{attachmentD.file.filename} (#{attachmentD.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentD.to_global_id,
      { 'data-puid': attachmentD.puid }],
    ["#{attachmentE.file.filename} (#{attachmentE.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentE.to_global_id,
      { 'data-puid': attachmentE.puid }],
    ["#{attachmentF.file.filename} (#{attachmentF.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentF.to_global_id,
      { 'data-puid': attachmentF.puid }]]
    expected_forward_files =
      [["#{attachmentPEFWD2.file.filename} (#{attachmentPEFWD2.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
        attachmentPEFWD2.to_global_id,
      { 'data-puid': attachmentPEFWD2.puid }],
      ["#{attachmentPEFWD3.file.filename} (#{attachmentPEFWD3.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentPEFWD3.to_global_id,
        { 'data-puid': attachmentPEFWD3.puid }],
      ["#{attachmentPEFWD1.file.filename} (#{attachmentPEFWD1.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentPEFWD1.to_global_id,
        { 'data-puid': attachmentPEFWD1.puid }]]
    expected_reverse_files =
      [["#{attachmentPEREV2.file.filename} (#{attachmentPEREV2.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
        attachmentPEREV2.to_global_id,
        { 'data-puid': attachmentPEREV2.puid }],
      ["#{attachmentPEREV3.file.filename} (#{attachmentPEREV3.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentPEREV3.to_global_id,
        { 'data-puid': attachmentPEREV3.puid }],
      ["#{attachmentPEREV1.file.filename} (#{attachmentPEREV1.created_at.localtime.strftime('%Y-%m-%d %l:%M%P')})",
      attachmentPEREV1.to_global_id,
        { 'data-puid': attachmentPEREV1.puid }]]

    assert_equal expected_singles_files, files[:singles]
    assert_equal expected_forward_files, files[:pe_forward]
    assert_equal expected_reverse_files, files[:pe_reverse]
  end

  test 'sorted_files with no attachments' do
    sample2 = samples(:sample2)

    files = sample2.sort_files

    assert files.empty?
  end
end
