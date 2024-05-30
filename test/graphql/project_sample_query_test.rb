# frozen_string_literal: true

require 'test_helper'

class ProjectSampleQueryTest < ActiveSupport::TestCase
  PROJECT_SAMPLE_QUERY_BY_SAMPLE_NAME = <<~GRAPHQL
    query($projectPuid: ID!, $sampleName: String!) {
      projectSample(projectPuid: $projectPuid, sampleName: $sampleName) {
        name
        description
        id
        puid
      }
    }
  GRAPHQL

  PROJECT_SAMPLE_QUERY_BY_SAMPLE_PUID = <<~GRAPHQL
    query($projectPuid: ID!, $samplePuid: ID!) {
      projectSample(projectPuid: $projectPuid, samplePuid: $samplePuid) {
        name
        description
        id
        puid
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'project sample query by sample name should work' do
    project = projects(:project1)
    sample = samples(:sample1)

    result = IridaSchema.execute(PROJECT_SAMPLE_QUERY_BY_SAMPLE_NAME, context: { current_user: @user },
                                                                      variables: { projectPuid: project.puid,
                                                                                   sampleName: sample.name })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projectSample']

    assert_not_empty data, 'sample type should work'
    assert_equal sample.name, data['name']

    assert_equal sample.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project sample query by sample puid should work' do
    project = projects(:project1)
    sample = samples(:sample1)

    result = IridaSchema.execute(PROJECT_SAMPLE_QUERY_BY_SAMPLE_PUID, context: { current_user: @user },
                                                                      variables: { projectPuid: project.puid,
                                                                                   samplePuid: sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projectSample']

    assert_not_empty data, 'sample type should work'
    assert_equal sample.name, data['name']

    assert_equal sample.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'project sample query should not return a result when unauthorized' do
    project = projects(:project1)
    sample = samples(:sample1)

    result = IridaSchema.execute(PROJECT_SAMPLE_QUERY_BY_SAMPLE_PUID, context: { current_user: users(:jane_doe) },
                                                                      variables: { projectPuid: project.puid,
                                                                                   samplePuid: sample.puid })

    assert_nil result['data']['projectSample']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'An object of type Sample was hidden due to permissions', error_message
  end
end
