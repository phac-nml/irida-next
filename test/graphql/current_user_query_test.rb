# frozen_string_literal: true

require 'test_helper'

class CurrentUserQueryTest < ActiveSupport::TestCase
  USER_QUERY = <<~GRAPHQL
    query {
      currentUser {
        email
        id
      }
    }
  GRAPHQL

  test 'current user query should work' do
    user = users(:john_doe)

    result = IridaSchema.execute(USER_QUERY, context: { current_user: user }, variables: {})

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['currentUser']

    assert_not_empty data, 'user type should work'
    assert_equal user.email, data['email']

    assert_equal user.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end
end
