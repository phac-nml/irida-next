# frozen_string_literal: true

require 'test_helper'

class CreateSampleMutationTest < ActiveSupport::TestCase
  CREATE_SAMPLE_USING_PROJECT_ID_MUTATION = <<~GRAPHQL
    mutation($projectId: ID!, $name: String!, $description: String!) {
      createSample(input: { projectId: $projectId, name: $name, description: $description }) {
        errors
        sample {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_SAMPLE_USING_PROJECT_PUID_MUTATION = <<~GRAPHQL
    mutation($projectPuid: ID!, $name: String!, $description: String!) {
      createSample(input: { projectPuid: $projectPuid, name: $name, description: $description }) {
        errors
        sample {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
  end

  test 'createSample mutation should work with valid params, project global id, and api scope token' do
    project = projects(:project1)

    result = IridaSchema.execute(CREATE_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project.to_global_id.to_s,
                                              name: 'New Sample One',
                                              description: 'New Sample One Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createSample']

    assert_not_empty data, 'createSample should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['sample']

    assert_equal 'New Sample One', data['sample']['name']
    assert_equal 'New Sample One Description', data['sample']['description']
  end

  test 'createSample mutation should work with valid params, project puid, and api scope token' do
    project = projects(:project1)

    result = IridaSchema.execute(CREATE_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectPuid: project.puid,
                                              name: 'New Sample Two',
                                              description: 'New Sample Two Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createSample']

    assert_not_empty data, 'createSample should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['sample']

    assert_equal 'New Sample Two', data['sample']['name']
    assert_equal 'New Sample Two Description', data['sample']['description']
  end

  test 'createSample mutation should not work with invalid params and api scope token' do
    project = projects(:project1)
    sample1 = samples(:sample1)

    result = IridaSchema.execute(CREATE_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project.to_global_id.to_s,
                                              name: sample1.name,
                                              description: sample1.description })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createSample']

    assert_not_empty data, 'createSample should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_nil data['sample'], 'sample should not be populated as one was not created.'

    assert_equal 'Name has already been taken', data['errors'][0]
  end

  test 'createSample mutation should not work with valid params and read api scope token' do
    project = projects(:project1)

    result = IridaSchema.execute(CREATE_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { projectId: project.to_global_id.to_s,
                                              name: 'New Sample',
                                              description: 'New Sample Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end
end
