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

  GROUP_SAMPLES_QUERY = <<~GRAPHQL
    query($group_id: ID!) {
      samples(groupId: $group_id) {
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

  test 'samples query should work for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)

    result = IridaSchema.execute(SAMPLES_QUERY, context: { current_user: user, token: },
                                                variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']

    assert_not_empty data, 'samples type should work'
    assert_not_empty data['nodes']
  end

  test 'group samples query should work' do
    result = IridaSchema.execute(GROUP_SAMPLES_QUERY, context: { current_user: @user },
                                                      variables:
                                                      { group_id: groups(:group_one).to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']

    assert_not_empty data, 'samples type should work'
    assert_not_empty data['nodes']
  end

  test 'group samples query should throw authorization error' do
    result = IridaSchema.execute(GROUP_SAMPLES_QUERY, context: { current_user: @user },
                                                      variables:
                                                      { group_id: groups(:group_a).to_global_id.to_s })

    assert_not_nil result['errors'], 'should not work and have authorization errors.'

    assert_equal "You are not authorized to view samples for group #{groups(:group_a).name} on this server.",
                 result['errors'].first['message']

    data = result['data']['samples']

    assert_nil data
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
