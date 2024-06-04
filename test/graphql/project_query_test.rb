# frozen_string_literal: true

require 'test_helper'

class ProjectQueryTest < ActiveSupport::TestCase
  PROJECT_QUERY_BY_FULL_PATH = <<~GRAPHQL
    query($projectPath: ID!) {
      project(fullPath: $projectPath) {
        name
        path
        description
        id
        fullName
        fullPath
      }
    }
  GRAPHQL

  PROJECT_QUERY_BY_PUID = <<~GRAPHQL
    query($projectPuid: ID!) {
      project(puid: $projectPuid) {
        name
        path
        description
        id
        fullName
        fullPath
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'project query by full_path should work' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY_BY_FULL_PATH, context: { current_user: @user },
                                                             variables: { projectPath: project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project query by puid should work' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY_BY_PUID, context: { current_user: @user },
                                                        variables: { projectPuid: project.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project query by puid should work when uploader access level' do
    user = users(:user_bot_account0)
    project = projects(:project1)
    token = personal_access_tokens(:user_bot_account0_valid_pat)

    result = IridaSchema.execute(PROJECT_QUERY_BY_PUID, context: { current_user: user, token: },
                                                        variables: { projectPuid: project.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project query should not return a result when unauthorized' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY_BY_FULL_PATH, context: { current_user: users(:jane_doe) },
                                                             variables: { projectPath: project.full_path })

    assert_nil result['data']['project']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.project.read?', name: project.name), error_message
  end

  test 'project query should not return a result when unauthorized due to expired token for uploader access level' do
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_expired_pat)
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY_BY_FULL_PATH, context: { current_user: user, token: },
                                                             variables: { projectPath: project.full_path })

    assert_nil result['data']['project']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.project.read?', name: project.name), error_message
  end
end
