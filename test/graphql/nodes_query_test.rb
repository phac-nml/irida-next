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

  NODES_PROJECTS_QUERY = <<~GRAPHQL
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        id
        ... on Project {
          name
        }
      }
    }
  GRAPHQL

  NODES_SAMPLES_QUERY = <<~GRAPHQL
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        id
        ... on Sample {
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

  test 'nodes query should work when passed a list of group ids with uploader access level' do
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_valid_pat)
    group = groups(:group_one)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: user, token: },
                                              variables: { ids: [group.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length
  end

  test 'nodes query should not return an unauthorized group' do
    user = users(:user_no_access)
    group = groups(:david_doe_group_four)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: user },
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

  test 'nodes query should work when passed a list of project ids' do
    project = projects(:project1)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: @user },
                                              variables: { ids: [project.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length
  end

  test 'nodes query should work when passed a list of project ids with uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    project = projects(:project1)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: user, token: },
                                              variables: { ids: [project.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length
  end

  test 'nodes query should not return an unauthorized project' do
    project = projects(:project1)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: users(:jane_doe) },
                                              variables: { ids: [project.to_global_id.to_s] })

    assert_not_nil result['errors'], 'should not work and have errors.'

    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Project was hidden due to permissions', error_message
  end

  test 'nodes query should not return samples from an unauthorized project' do
    project = projects(:project1)

    result = IridaSchema.execute(NODES_QUERY, context: { current_user: users(:jane_doe) },
                                              variables: { ids: [project.samples[0].to_global_id.to_s] })

    assert_not_nil result['errors'], 'should not work and have errors.'

    error_message = result['errors'][0]['message']
    assert_equal 'An object of type Sample was hidden due to permissions', error_message
  end

  test 'nodes query for project should be able to return project attributes' do
    project = projects(:project1)

    result = IridaSchema.execute(NODES_PROJECTS_QUERY, context: { current_user: @user },
                                                       variables: { ids: [project.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length

    assert_equal project.name, data[0]['name']
  end

  test 'nodes query for sample should be able to return sample attributes' do
    sample = samples(:sample1)

    result = IridaSchema.execute(NODES_SAMPLES_QUERY, context: { current_user: @user },
                                                      variables: { ids: [sample.to_global_id.to_s] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['nodes']

    assert_not_empty data, 'nodes type should work'
    assert_equal 1, data.length

    assert_equal sample.name, data[0]['name']
  end
end
