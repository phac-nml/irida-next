# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
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

  test 'metadata_with_provenance' do
    sample = samples(:sample32)
    user = users(:john_doe)
    expected_metadata_with_provenance = [{
      key: 'metadatafield1',
      value: 'value1',
      source: user.email,
      last_updated: DateTime.new(2000, 1, 1)
    }, {
      key: 'metadatafield2',
      value: 'value2',
      source: user.email,
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
end
