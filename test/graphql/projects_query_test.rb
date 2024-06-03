# frozen_string_literal: true

require 'test_helper'

class ProjectsQueryTest < ActiveSupport::TestCase
  PROJECTS_QUERY = <<~GRAPHQL
    query($first: Int) {
      projects(first: $first) {
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

  test 'projects query should work' do
    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: @user },
                                                 variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']
  end

  test 'projects query should work for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)

    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: user, token: },
                                                 variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']
  end

  test 'projects query only returns scoped projects' do
    policy = ProjectPolicy.new(user: @user)
    projects_count = policy.apply_scope(Project, type: :relation).count
    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: @user },
                                                 variables: { first: 20 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']

    assert_equal projects_count, data['totalCount']
  end
end
