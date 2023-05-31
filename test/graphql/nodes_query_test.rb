# frozen_string_literal: true

require 'test_helper'

class NodesQueryTest < ActiveSupport::TestCase
  NODES_QUERY = <<~GRAPHQL
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        id
      }
    }
  GRAPHQL

  NODES_GROUPS_QUERY = <<~GRAPHQL
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        id
        ... on Group {
          name
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'nodes query should work when passed a list of group ids' do
    group = groups(:group_one)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: @user },
                                              variables: { ids: [group.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length
  end

  test 'nodes query should not return an unauthorized group' do
    group = groups(:david_doe_group_four)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: @user },
                                              variables: { ids: [group.to_global_id.to_s] })

    assert_not_nil result['errors'], 'should not work and have errors.'

    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Group was hidden due to permissions', error_message
  end

  test 'nodes query for group should be able to return group attributes' do
    group = groups(:group_one)

    result = IridaSchema.execute(NODES_GROUPS_QUERY, context: { current_user: @user },
                                                     variables: { ids: [group.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length

    assert_equal group.name, data[0]['name']
  end
end
