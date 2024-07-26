# frozen_string_literal: true

require 'test_helper'

class UpdateSampleMetadataMutationTest < ActiveSupport::TestCase
  UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION = <<~GRAPHQL
    mutation($sampleId: ID!, $metadata: JSON!) {
      updateSampleMetadata(input: { sampleId: $sampleId, metadata: $metadata }) {
        sample {
          id,
          name,
          description,
          metadata
        },
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION = <<~GRAPHQL
    mutation($samplePuid: ID!, $metadata: JSON!) {
      updateSampleMetadata(input: { samplePuid: $samplePuid, metadata: $metadata }) {
        sample {
          id,
          name,
          description,
          metadata
        },
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
    @sample = samples(:sample1)
  end

  test 'updateSampleMetadata mutation should work with valid params, global id, and api scope token' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: { key1: 'value1' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['status']
    assert_not_empty data['status'][:added]
    assert_equal 'key1', data['status'][:added].first
    assert_not_empty data['sample']
    assert_not_empty data['sample']['metadata']
    assert_not_empty data['sample']['metadata']['key1']
    assert_equal 'value1', data['sample']['metadata']['key1']
  end

  test 'updateSampleMetadata mutation should work with valid params, puid, and api scope token' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { samplePuid: @sample.puid,
                                              metadata: { key1: 'value1' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['status']
    assert_not_empty data['status'][:added]
    assert_equal 'key1', data['status'][:added].first
    assert_not_empty data['sample']
    assert_not_empty data['sample']['metadata']
    assert_not_empty data['sample']['metadata']['key1']
    assert_equal 'value1', data['sample']['metadata']['key1']
  end

  test 'updateSampleMetadata mutation should work with valid JSON String params, global id, and api scope token' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: "{ \"key1\": \"value1\" }" }) # rubocop:disable Style/StringLiterals

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['status']
    assert_not_empty data['status'][:added]
    assert_equal 'key1', data['status'][:added].first
    assert_not_empty data['sample']
    assert_not_empty data['sample']['metadata']
    assert_not_empty data['sample']['metadata']['key1']
    assert_equal 'value1', data['sample']['metadata']['key1']
  end

  test 'updateSampleMetadata mutation should work with valid params, puid, and api scope token with uploader access level' do # rubocop:disable Layout/LineLength
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { samplePuid: @sample.puid,
                                              metadata: { key1: 'value1' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['status']
    assert_not_empty data['status'][:added]
    assert_equal 'key1', data['status'][:added].first
    assert_not_empty data['sample']
    assert_not_empty data['sample']['metadata']
    assert_not_empty data['sample']['metadata']['key1']
    assert_equal 'value1', data['sample']['metadata']['key1']
  end

  test 'updateSampleMetadata mutation should error with empty metadata params and api scope token' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: {} })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['status'][:added], 'status added changes should be empty as the sample was not updated.'
    assert_empty data['status'][:updated], 'status updated changes should be empty as the sample was not updated.'
    assert_empty data['status'][:deleted], 'status deleted changes should be empty as the sample was not updated.'
    assert_empty data['status'][:not_updated],
                 'status not_updated changes should be empty as the sample was not updated.'
    assert_not_empty data['errors']
    expected_error = {
      'path' => %w[sample base],
      'message' => I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
    }
    assert_equal expected_error, data['errors'][0]
  end

  test 'updateSampleMetadata mutation should not work with valid params and read api scope token' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: { key1: 'value1' } })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'updateSampleMetadata mutation should not work with valid params and no permission' do
    user = users(:jane_doe)
    api_scope_token = personal_access_tokens(:jane_doe_valid_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: user, token: api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: { key1: 'value1' } })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample.project.name), error_message
  end

  test 'updateSampleMetadata mutation should not work with valid params due to expired token for uploader access level' do # rubocop:disable Layout/LineLength
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: { key1: 'value1' } })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to update samples for project Project 1 on this server.', error_message
  end

  test 'updateSampleMetadata mutation should not work with invalid sample id' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: 'not a sample id',
                                              metadata: { key1: 'value1' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']

    expected_error = [
      'path' => ['sample'],
      'message' => 'not a sample id is not a valid IRIDA Next ID.'
    ]
    assert_equal expected_error, data['errors']
  end

  test 'updateSampleMetadata mutation should not work with invalid sample puid' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { samplePuid: 'not a sample puid',
                                              metadata: { key1: 'value1' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']

    expected_error = [
      'path' => ['sample'],
      'message' => 'not found by provided ID or PUID'
    ]
    assert_equal expected_error, data['errors']
  end

  test 'updateSampleMetadata mutation should not work with invalid JSON formatting' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: "bad formatting" }) # rubocop:disable Style/StringLiterals,Lint/RedundantCopDisableDirective

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data
    assert_not_empty data['errors']

    expected_error = [
      'path' => ['metadata'],
      'message' => "JSON data is not formatted correctly. unexpected token at 'bad formatting'"
    ]
    assert_equal expected_error, data['errors']
  end

  test 'updateSampleMetadata mutation should not work with non JSON data' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { sampleId: @sample.to_global_id.to_s,
                                              metadata: 1234 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']

    assert_not_empty data
    assert_not_empty data['errors']

    expected_error = [
      'path' => ['metadata'],
      'message' => 'is not JSON data'
    ]
    assert_equal expected_error, data['errors']
  end
end
