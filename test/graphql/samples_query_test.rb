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

  def setup
    @user = users(:john_doe)
  end

  test 'samples query should work' do
    result = IridaSchema.execute(SAMPLES_QUERY, context: { current_user: @user },
                                                variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']

    assert_not_empty data, 'samples type should work'
    assert_not_empty data['nodes']
  end
end
