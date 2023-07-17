# frozen_string_literal: true

require 'test_helper'

class ProjectQueryTest < ActiveSupport::TestCase
  PROJECT_QUERY = <<~GRAPHQL
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

  def setup
    @user = users(:john_doe)
  end

  test 'project query should work' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: @user },
                                                variables: { projectPath: project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project query should not return a result when unauthorized' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: users(:jane_doe) },
                                                variables: { projectPath: project.full_path })

    assert_nil result['data']['project']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.project.read?', name: project.name), error_message
  end
end
