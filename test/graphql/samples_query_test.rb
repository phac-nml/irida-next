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
  end
end
