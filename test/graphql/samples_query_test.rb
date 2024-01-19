# frozen_string_literal: true

require 'test_helper'

class SamplesQueryTest < ActiveSupport::TestCase
  SAMPLES_QUERY = <<~GRAPHQL
    query($first: Int) {
      samples(first: $first) {
        nodes {
          name
          description
          id
          project {
            id
          }
        }
        totalCount
      }
    }
  GRAPHQL

  SAMPLE_AND_METADATA_QUERY = <<~GRAPHQL
    query($sample_id: ID!) {
      sample: node(id: $sample_id) {
        ... on Sample {
          name
          description
          id
          metadata
        }
      }
    }
  GRAPHQL

  SAMPLE_AND_LIMITED_METADATA_QUERY = <<~GRAPHQL
    query($sample_id: ID!, $keys: [String!]) {
      sample: node(id: $sample_id) {
        ... on Sample {
          name
          description
          id
          metadata(keys: $keys)
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @sample = samples(:sample1)
    @sample32 = samples(:sample32)
  end

  test 'samples query should work' do
    result = IridaSchema.execute(SAMPLES_QUERY, context: { current_user: @user },
                                                variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']

    assert_not_empty data, 'samples type should work'
    assert_not_empty data['nodes']
  end

  test 'sample and metadata fields query should work' do
    result = IridaSchema.execute(SAMPLE_AND_METADATA_QUERY, context: { current_user: @user },
                                                            variables: { sample_id: @sample32.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'
    assert_equal @sample32.metadata, data['metadata']
    assert data['metadata'].key?('metadatafield1')
    assert data['metadata'].key?('metadatafield2')
  end

  test 'sample and metadata fields query should be able to limit to a specific set of keys' do
    result = IridaSchema.execute(SAMPLE_AND_LIMITED_METADATA_QUERY,
                                 context: { current_user: @user },
                                 variables: { sample_id: @sample32.to_global_id.to_s, keys: ['metadatafield1'] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'
    assert_not_equal @sample32.metadata, data['metadata']
    assert data['metadata'].key?('metadatafield1')
    assert_not data['metadata'].key?('metadatafield2')
  end

  test 'sample and metadata fields query with non-existing keys should return empty metadata hash' do
    result = IridaSchema.execute(SAMPLE_AND_LIMITED_METADATA_QUERY,
                                 context: { current_user: @user },
                                 variables: { sample_id: @sample32.to_global_id.to_s, keys: ['nometadatafield'] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'
    assert_not_equal @sample32.metadata, data['metadata']
    assert_not data['metadata'].key?('metadatafield1')
    assert_not data['metadata'].key?('metadatafield2')
    assert_empty data['metadata']
  end
end
