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

  ORDERED_PROJECTS_QUERY = <<~GRAPHQL
    query($first: Int, $order_by: ProjectOrder) {
      projects(first: $first, orderBy: $order_by) {
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

  test 'projects query should throw authorization error due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)

    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: user, token: },
                                                 variables: { first: 20 })

    assert_not_nil result['errors'], 'should not work and have authorization errors.'
    error_message = result['errors'][0]['message']
    assert_equal 'You are not authorized to perform this action',
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

  test 'projects query applies a default order of created_at asc' do
    result = IridaSchema.execute(PROJECTS_QUERY, context: { current_user: @user },
                                                 variables: { first: 20 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']

    created_at_values = data['nodes'].map { |node| node['createdAt'] } # rubocop:disable Rails/Pluck
    assert_equal created_at_values.sort, created_at_values
  end

  test 'projects query applies a default direction of ascending' do
    result = IridaSchema.execute(ORDERED_PROJECTS_QUERY, context: { current_user: @user },
                                                         variables: { first: 20, order_by: { field: 'updated_at' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_not_empty data['nodes']

    updated_at_values = data['nodes'].map { |node| node['updated_at'] } # rubocop:disable Rails/Pluck
    assert_equal updated_at_values.sort { |a, b| b <=> a }, updated_at_values
  end
end
