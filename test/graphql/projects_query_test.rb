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

  GROUP_PROJECTS_QUERY = <<~GRAPHQL
    query($group_id: ID!) {
      projects(groupId: $group_id) {
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

  test 'projects query should work but with errors due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)

    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: user, token: },
                                                 variables: { first: 20 })

    assert_not_nil result['errors'], 'should work and have errors.'
    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Project was hidden due to permissions',
                 error_message
  end

  test 'group projects query should work' do
    result = IridaSchema.execute(GROUP_PROJECTS_QUERY, context: { current_user: @user },
                                                       variables:
                                                      { group_id: groups(:group_one).to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']
  end

  test 'group projects query should throw authorization error' do
    result = IridaSchema.execute(GROUP_PROJECTS_QUERY, context: { current_user: @user },
                                                       variables:
                                                      { group_id: groups(:group_a).to_global_id.to_s })

    assert_not_nil result['errors'], 'should not work and have authorization errors.'

    assert_equal "You are not authorized to view group #{groups(:group_a).name} on this server.",
                 result['errors'].first['message']

    data = result['data']['projects']

    assert_nil data
  end
end
