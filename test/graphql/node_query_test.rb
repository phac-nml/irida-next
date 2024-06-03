# frozen_string_literal: true

require 'test_helper'

class NodeQueryTest < ActiveSupport::TestCase
  NODE_QUERY = <<~GRAPHQL
    query($id: ID!) {
      node(id: $id) {
        id
      }
    }
  GRAPHQL

  NODE_GROUP_QUERY = <<~GRAPHQL
    query($id: ID!) {
      node(id: $id) {
        id
        ... on Group {
          name
        }
      }
    }
  GRAPHQL

  NODE_PROJECT_QUERY = <<~GRAPHQL
    query($id: ID!) {
      node(id: $id) {
        id
        ... on Project {
          name
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'node query should work for group' do
    group = groups(:group_one)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: @user },
                                             variables: { id: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal group.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'node query should work for group with uploader access level' do
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_valid_pat)
    group = groups(:group_one)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: user, token: },
                                             variables: { id: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal group.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'node query should not return an unauthorized group' do
    @user = users(:user_no_access)
    group = groups(:david_doe_group_four)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: @user },
                                             variables: { id: group.to_global_id.to_s })

    assert_not_nil result['errors'], 'should not work and have errors.'

    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Group was hidden due to permissions', error_message
  end

  test 'node query for group should be able to return group attributes' do
    group = groups(:group_one)

    result = IridaSchema.execute(NODE_GROUP_QUERY, context: { current_user: @user },
                                                   variables: { id: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal group.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal group.name, data['name']
  end

  test 'node query should work for project' do
    project = projects(:project1)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: @user },
                                             variables: { id: project.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'node query should work for project with uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    project = projects(:project1)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: user, token: },
                                             variables: { id: project.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'node query should not return an unauthorized project' do
    project = projects(:project1)

    result = IridaSchema.execute(NODE_QUERY, context: { current_user: users(:jane_doe) },
                                             variables: { id: project.to_global_id.to_s })

    assert_not_nil result['errors'], 'should not work and have errors.'

    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Project was hidden due to permissions', error_message
  end

  test 'node query for project should be able to return project attributes' do
    project = projects(:project1)

    result = IridaSchema.execute(NODE_PROJECT_QUERY, context: { current_user: @user },
                                                     variables: { id: project.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']

    assert_not_empty data, 'node type should work'
    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal project.name, data['name']
  end
end
