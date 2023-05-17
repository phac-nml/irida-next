# frozen_string_literal: true

require 'test_helper'

class GroupsQueryTest < ActiveSupport::TestCase
  GROUPS_QUERY = <<~GRAPHQL
    query($first: Int) {
      groups(first: $first) {
        nodes {
          name
          path
          description
          id
        }
        totalCount
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'groups query should work' do
    result = IridaSchema.execute(GROUPS_QUERY, context: { current_user: @user },
                                               variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['groups']

    assert_not_empty data, 'groups type should work'
    assert_not_empty data['nodes']
  end

  test 'groups query only returns scoped groups' do
    groups_count = @user.groups.self_and_descendant_ids.count
    result = IridaSchema.execute(GROUPS_QUERY, context: { current_user: @user },
                                               variables: { first: 20 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['groups']

    assert_not_empty data, 'groups type should work'
    assert_not_empty data['nodes']

    assert_equal groups_count, data['totalCount']
  end
end
