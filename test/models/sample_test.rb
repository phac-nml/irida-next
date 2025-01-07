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

    files = sample_b.sorted_files

    assert_equal 3, files[:singles].count
    assert_equal 3, files[:pe_forward].count
    assert_equal 3, files[:pe_reverse].count
  end

  test 'sorted_files with no attachments' do
    sample2 = samples(:sample2)

    files = sample2.sorted_files

    assert files.empty?
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
end
