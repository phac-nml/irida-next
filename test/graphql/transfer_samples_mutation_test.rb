# frozen_string_literal: true

require 'test_helper'

class TransferSamplesMutationTest < ActiveSupport::TestCase
  TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION = <<~GRAPHQL
    mutation($projectId: ID!, $newProjectId: ID!, $sampleIds: [ID!]!) {
      transferSamples(input: { projectId: $projectId, newProjectId: $newProjectId, sampleIds: $sampleIds }) {
        errors {
          path
          message
        }
        samples
      }
    }
  GRAPHQL

  TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION = <<~GRAPHQL
    mutation($projectPuid: ID!, $newProjectPuid: ID!, $sampleIds: [ID!]!) {
      transferSamples(input: { projectPuid: $projectPuid, newProjectPuid: $newProjectPuid, sampleIds: $sampleIds }) {
        errors {
          path
          message
        }
        samples
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
  end

  test 'transferSamples mutation should work with valid params, project global ids, and api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    p1_sample_count = project1.samples.count
    p2_sample_count = project2.samples.count

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSample should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['samples']

    data['samples'].each do |sample_id|
      sample = IridaSchema.object_from_id(sample_id, { expected_type: Sample })
      assert_equal project2.id, sample.project.id
    end

    assert_equal p1_sample_count - 2, project1.samples.count
    assert_equal p2_sample_count + 2, project2.samples.count
  end

  test 'transferSamples mutation should work with valid params, puids, and api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    p1_sample_count = project1.samples.count
    p2_sample_count = project2.samples.count

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectPuid: project1.puid,
                                              newProjectPuid: project2.puid,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSample should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['samples']

    data['samples'].each do |sample_id|
      sample = IridaSchema.object_from_id(sample_id, { expected_type: Sample })
      assert_equal project2.id, sample.project.id
    end

    assert_equal p1_sample_count - 2, project1.samples.count
    assert_equal p2_sample_count + 2, project2.samples.count
  end

  test 'transferSamples mutation should not work with valid params, puids, and api scope token with uploader access level' do # rubocop:disable Layout/LineLength
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { projectPuid: project1.puid,
                                              newProjectPuid: project2.puid,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['errors'], 'should have errors.'

    assert_not_empty result['errors']
    assert_equal 'You are not authorized to transfer samples for project Project 1 on this server.',
                 result['errors'][0]['message']
    assert_equal ['transferSamples'], result['errors'][0]['path']
  end

  test 'transferSamples mutation should not work with invalid params and api scope token' do
    project1 = projects(:project1)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectPuid: project1.puid,
                                              newProjectPuid: project1.puid,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSamples should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_nil data['samples'], 'sample should not be populated as one was not created.'

    assert_equal %w[samples base], data['errors'][0]['path']
    assert_equal 'The samples already exist in the project. Please select a different project.',
                 data['errors'][0]['message']
  end

  test 'transferSamples mutation should not work with valid params and read api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'transferSamples mutation should not work with valid params due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'transferSamples mutation should not work with unauthorized project and valid api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: users(:jane_doe),
                                            token: personal_access_tokens(:jane_doe_valid_pat) },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project2.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t(:'action_policy.policy.project.transfer_sample?', name: project1.name), error_message
  end

  test 'transferSamples mutation should not work with invalid original project puid and valid api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectPuid: 'INVALID_PUID',
                                              newProjectPuid: project2.puid,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['data']['transferSamples']['errors'], 'shouldn\'t work and have errors.'

    errors = result['data']['transferSamples']['errors']

    assert_equal 'Project not found by provided ID or PUID', errors[0]['message']
  end

  test 'transferSamples mutation should not work with invalid target project puid and valid api scope token' do
    project1 = projects(:project1)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectPuid: project1.puid,
                                              newProjectPuid: 'INVALID_PUID',
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_not_nil result['data']['transferSamples']['errors'], 'shouldn\'t work and have errors.'

    errors = result['data']['transferSamples']['errors']

    assert_equal 'Project not found by provided ID or PUID', errors[0]['message']
  end

  test 'transferSamples mutation should not work with invalid original project id and valid api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: 'gid://irida/Project/not-a-valid-uuid',
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    expected_error = { 'message' => 'Project not found by provided ID or PUID', 'path' => ['project'] }

    assert_equal expected_error, result['data']['transferSamples']['errors'][0]
  end

  test 'transferSamples mutation should not work with invalid target project id and valid api scope token' do
    project1 = projects(:project1)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: 'gid://irida/Project/not-a-valid-uuid',
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    expected_error = { 'message' => 'Project not found by provided ID or PUID', 'path' => ['new_project'] }

    assert_equal expected_error, result['data']['transferSamples']['errors'][0]
  end

  test 'transferSamples mutation should not work with incorrectly formatted project id and valid api scope token' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: 'project_ids_dont_look_like_this',
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    expected_error = { 'message' => 'project_ids_dont_look_like_this is not a valid IRIDA Next ID.',
                       'locations' => [{ 'line' => 2, 'column' => 3 }], 'path' => ['transferSamples'] }

    assert_equal expected_error, result['errors'][0]
  end

  test 'transferSamples mutation should fail when transfering to self' do
    project1 = projects(:project1)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project1.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSample should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'The samples already exist in the project. Please select a different project.',
                 data['errors'][0]['message']
  end

  test 'transferSamples mutation should fail when sample is not on original project' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project2.to_global_id.to_s,
                                              newProjectId: project1.to_global_id.to_s,
                                              sampleIds: [
                                                project1.samples[0].to_global_id.to_s,
                                                project1.samples[1].to_global_id.to_s
                                              ] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSample should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert data['errors'][0]['message'].include?('Samples with the following sample ids could not be transferred as they were not found in the source project:') # rubocop:disable Layout/LineLength
  end

  test 'transferSamples mutation should fail when no samples given' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    result = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { projectId: project1.to_global_id.to_s,
                                              newProjectId: project2.to_global_id.to_s,
                                              sampleIds: [] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['transferSamples']

    assert_not_empty data, 'transferSample should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'The sample ids are empty.', data['errors'][0]['message']
  end

  test 'transferSamples mutation should work when transfering a sample back and forth' do
    project1 = projects(:project1)
    project2 = projects(:project2)

    p1_sample_count = project1.samples.count
    p2_sample_count = project2.samples.count

    result1 = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                  context: { current_user: @user, token: @api_scope_token },
                                  variables: { projectId: project1.to_global_id.to_s,
                                               newProjectId: project2.to_global_id.to_s,
                                               sampleIds: [
                                                 project1.samples[0].to_global_id.to_s
                                               ] })

    assert_nil result1['errors'], 'should work and have no errors.'

    data1 = result1['data']['transferSamples']

    assert_not_empty data1, 'transferSample should be populated when no authorization errors'
    assert_empty data1['errors']
    assert_not_empty data1['samples']

    sample1 = IridaSchema.object_from_id(data1['samples'][0], { expected_type: Sample })
    assert_equal project2.id, sample1.project.id

    assert_equal p1_sample_count - 1, project1.samples.count
    assert_equal p2_sample_count + 1, project2.samples.count

    # Now transfer the sample back
    result2 = IridaSchema.execute(TRANSFER_SAMPLE_USING_PROJECT_ID_MUTATION,
                                  context: { current_user: @user, token: @api_scope_token },
                                  variables: { projectId: project2.to_global_id.to_s,
                                               newProjectId: project1.to_global_id.to_s,
                                               sampleIds: [
                                                 sample1.to_global_id.to_s
                                               ] })

    assert_nil result2['errors'], 'should work and have no errors.'

    data2 = result2['data']['transferSamples']

    assert_not_empty data2, 'transferSample should be populated when no authorization errors'
    assert_empty data2['errors']
    assert_not_empty data2['samples']

    assert_equal project1.id, sample1.reload.project.id

    assert_equal p1_sample_count, project1.samples.count
    assert_equal p2_sample_count, project2.samples.count
  end
end
