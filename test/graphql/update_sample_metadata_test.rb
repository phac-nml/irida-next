# frozen_string_literal: true

require 'test_helper'

class UpdateSampleMetadataMutationTest < ActiveSupport::TestCase
  UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION = <<~GRAPHQL
    mutation($metadataPayload: JSON!, $projectId: ID!) {
      updateSampleMetadata(input: { metadataPayload: $metadataPayload, projectId: $projectId }) {
        samples,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_PROJECT_PUID_MUTATION = <<~GRAPHQL
    mutation($metadataPayload: JSON!, $projectPuid: ID!) {
      updateSampleMetadata(input: { metadataPayload: $metadataPayload, projectPuid: $projectPuid }) {
        samples,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION = <<~GRAPHQL
    mutation($metadataPayload: JSON!, $groupId: ID!) {
      updateSampleMetadata(input: { metadataPayload: $metadataPayload, groupId: $groupId }) {
        samples,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_GROUP_PUID_MUTATION = <<~GRAPHQL
    mutation($metadataPayload: JSON!, $groupPuid: ID!) {
      updateSampleMetadata(input: { metadataPayload: $metadataPayload, groupPuid: $groupPuid }) {
        samples,
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
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @sample3 = samples(:sample3)
    @sample4 = samples(:sample4)
    @sample5 = samples(:sample5)
    @project1 = projects(:project1)
    @project2 = projects(:project2)
    @group1 = groups(:group_one)
  end

  test 'updateSampleMetadata mutation should work with valid params, project puid, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              projectPuid: @project2.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful with no errors', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'updateSampleMetadata mutation should work with valid params, project id, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful with no errors', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'updateSampleMetadata mutation should work with valid params, group puid, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              groupPuid: @group1.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful with no errors', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'updateSampleMetadata mutation should work with valid params, group id, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful with no errors', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'updateSampleMetadata mutation at group level with partial success' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
                         'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful with errors', data['status']
    assert_equal [@sample3.to_global_id.to_s], data['samples']

    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
  end

  test 'updateSampleMetadata mutation at project level with partial success' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
                         'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful with errors', data['status']
    assert_equal [@sample3.to_global_id.to_s], data['samples']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
  end

  test 'updateSampleMetadata mutation at group level with no success' do
    metadata_payload = {
      'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
      'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' }
    }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['status']
    assert_empty data['samples']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
  end

  test 'updateSampleMetadata mutation at project level with no success' do
    metadata_payload = {
      'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
      'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' }
    }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['status']
    assert_empty data['samples']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
  end

  test 'updateSampleMetadata mutation should work with valid params and api scope token with uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)

    assert @sample1.metadata.empty?
    assert @sample2.metadata.empty?
    metadata_payload = { @sample1.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample2.name => { 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project1.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful with no errors', data['status']
    assert_equal 2, data['samples'].count
    assert_includes(data['samples'], @sample1.to_global_id.to_s)
    assert_includes(data['samples'], @sample2.name)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample1.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' }, @sample2.reload.metadata)
  end

  # TODO: check project vs namespace policy
  # test 'updateSampleMetadata mutation should work with valid params and api scope token with uploader access level' do
  #   user = users(:user_bot_account0)
  #   token = personal_access_tokens(:user_bot_account0_valid_pat)

  #   assert @sample1.metadata.empty?
  #   assert @sample2.metadata.empty?
  #   metadata_payload = { @sample1.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
  #                        @sample2.name => { 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' } }
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
  #                                context: { current_user: user, token: },
  #                                variables: { metadataPayload: metadata_payload,
  #                                             projectId: @project1.to_global_id.to_s })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']
  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']
  #   assert_equal 'successful with no errors', data['status']

  #   assert_equal({ 'newmetadatafield1' => 'value1' }, @sample1.reload.metadata)
  #   assert_equal({ 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' }, @sample2.reload.metadata)
  # end

  # test 'updateSampleMetadata mutation should error with empty metadata params and api scope token' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: {} })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['status'][:added], 'status added changes should be empty as the sample was not updated.'
  #   assert_empty data['status'][:updated], 'status updated changes should be empty as the sample was not updated.'
  #   assert_empty data['status'][:deleted], 'status deleted changes should be empty as the sample was not updated.'
  #   assert_empty data['status'][:not_updated],
  #                'status not_updated changes should be empty as the sample was not updated.'
  #   assert_not_empty data['errors']
  #   expected_error = {
  #     'path' => %w[sample base],
  #     'message' => I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
  #   }
  #   assert_equal expected_error, data['errors'][0]
  # end

  # test 'updateSampleMetadata mutation should not work with valid params and read api scope token' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @read_api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { key1: 'value1' } })

  #   assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

  #   error_message = result['errors'][0]['message']

  #   assert_equal 'You are not authorized to perform this action', error_message
  # end

  # test 'updateSampleMetadata mutation should not work with valid params and no permission' do
  #   user = users(:jane_doe)
  #   api_scope_token = personal_access_tokens(:jane_doe_valid_pat)

  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: user, token: api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { key1: 'value1' } })

  #   assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

  #   error_message = result['errors'][0]['message']

  #   assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample.project.name), error_message
  # end

  # test 'updateSampleMetadata mutation should not work with valid params due to expired token for uploader access level' do # rubocop:disable Layout/LineLength
  #   user = users(:user_bot_account0)
  #   token = personal_access_tokens(:user_bot_account0_expired_pat)

  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: user, token: },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { key1: 'value1' } })

  #   assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

  #   error_message = result['errors'][0]['message']

  #   assert_equal 'You are not authorized to perform this action', error_message
  # end

  # test 'updateSampleMetadata mutation should not work with invalid sample id' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: 'not a sample id',
  #                                             metadata: { key1: 'value1' } })

  #   expected_error = [
  #     { 'message' => 'not a sample id is not a valid IRIDA Next ID.', 'locations' => [{ 'line' => 2, 'column' => 3 }],
  #       'path' => ['updateSampleMetadata'] }
  #   ]
  #   assert_equal expected_error, result['errors']
  # end

  # test 'updateSampleMetadata mutation should not work with non existing sample id' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: 'gid://irida/Sample/doesnotexist',
  #                                             metadata: { key1: 'value1' } })

  #   expected_error = [{ 'message' => 'not found by provided ID or PUID', 'path' => ['sample'] }]
  #   assert_equal expected_error, result['data']['updateSampleMetadata']['errors']
  # end

  # test 'updateSampleMetadata mutation should not work with invalid sample puid' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { samplePuid: 'not a sample puid',
  #                                             metadata: { key1: 'value1' } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_not_empty data['errors']

  #   expected_error = [{
  #     'path' => ['sample'],
  #     'message' => 'not found by provided ID or PUID'
  #   }]
  #   assert_equal expected_error, data['errors']
  # end

  # test 'updateSampleMetadata mutation should not work with invalid JSON formatting' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: "bad formatting" }) # rubocop:disable Style/StringLiterals,Lint/RedundantCopDisableDirective

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data
  #   assert_not_empty data['errors']

  #   expected_error = [{
  #     'path' => ['metadata'],
  #     'message' => "JSON data is not formatted correctly. unexpected character: 'bad' at line 1 column 1"
  #   }]
  #   assert_equal expected_error, data['errors']
  # end

  # test 'updateSampleMetadata mutation should not work with non JSON data' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: 1234 })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data
  #   assert_not_empty data['errors']

  #   expected_error = [{
  #     'path' => ['metadata'],
  #     'message' => 'is not JSON data'
  #   }]
  #   assert_equal expected_error, data['errors']
  # end

  # test 'updateSampleMetadata mutation should not work with nested metadata' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_PUID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { samplePuid: @sample.puid,
  #                                             metadata: { key1: { nestedKey1: 'nestedValue1' } } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data
  #   assert_not_empty data['errors']

  #   expected_error = [{
  #     'path' => %w[sample base],
  #     'message' => I18n.t('services.samples.metadata.nested_metadata', sample_name: @sample.name, key: 'key1')
  #   }]
  #   assert_equal expected_error, data['errors']
  # end

  # test 'updateSampleMetadata mutation should convert keys and values to strings and lower case keys' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { integer: 1, True_Boolean: true, false_boolean: false,
  #                                                         date: Date.parse('2024-03-11'), string: 'A Test', empty: '',
  #                                                         nil: nil } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']

  #   assert_not_empty data['status']
  #   assert_not_empty data['status'][:added]
  #   assert data['status'][:added].include?('integer')
  #   assert data['status'][:added].include?('true_boolean')
  #   assert data['status'][:added].include?('false_boolean')
  #   assert data['status'][:added].include?('date')
  #   assert data['status'][:added].include?('string')
  #   assert_not data['status'][:added].include?('empty')
  #   assert_not data['status'][:added].include?('nil')

  #   assert_not_empty data['sample']
  #   assert_not_empty data['sample']['metadata']
  #   assert_not_empty data['sample']['metadata']['integer']
  #   assert data['sample']['metadata'].include?('integer')
  #   assert_equal '1', data['sample']['metadata']['integer']
  #   assert data['sample']['metadata'].include?('true_boolean')
  #   assert_equal 'true', data['sample']['metadata']['true_boolean']
  #   assert data['sample']['metadata'].include?('false_boolean')
  #   assert_equal 'false', data['sample']['metadata']['false_boolean']
  #   assert data['sample']['metadata'].include?('date')
  #   assert_equal '2024-03-11', data['sample']['metadata']['date']
  #   assert data['sample']['metadata'].include?('string')
  #   assert_equal 'A Test', data['sample']['metadata']['string']
  #   assert_not data['sample']['metadata'].include?('empty')
  #   assert_not data['sample']['metadata'].include?('nil')
  # end

  # test 'updateSampleMetadata mutation should strip leading/trailing whitespaces from metadata value' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { key1: '    value 1     ' } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']
  #   assert_not_empty data['status']
  #   assert_not_empty data['status'][:added]
  #   assert_equal 'key1', data['status'][:added].first
  #   assert_not_empty data['sample']
  #   assert_not_empty data['sample']['metadata']
  #   assert_not_empty data['sample']['metadata']['key1']
  #   assert_equal 'value 1', data['sample']['metadata']['key1']
  # end

  # test 'updateSampleMetadata mutation converts multiple inner whitespaces into single whitespace for value' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { key1: '    value          1     ' } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']
  #   assert_not_empty data['status']
  #   assert_not_empty data['status'][:added]
  #   assert_equal 'key1', data['status'][:added].first
  #   assert_not_empty data['sample']
  #   assert_not_empty data['sample']['metadata']
  #   assert_not_empty data['sample']['metadata']['key1']
  #   assert_equal 'value 1', data['sample']['metadata']['key1']
  # end

  # test 'updateSampleMetadata mutation should strip leading/trailing whitespaces from metadata key' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { '   key1   ' => '    value 1     ' } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']
  #   assert_not_empty data['status']
  #   assert_not_empty data['status'][:added]
  #   assert_equal 'key1', data['status'][:added].first
  #   assert_not_empty data['sample']
  #   assert_not_empty data['sample']['metadata']
  #   assert_not_empty data['sample']['metadata']['key1']
  #   assert_equal 'value 1', data['sample']['metadata']['key1']
  # end

  # test 'updateSampleMetadata mutation converts multiple inner whitespaces into single whitespace for key' do
  #   result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_SAMPLE_ID_MUTATION,
  #                                context: { current_user: @user, token: @api_scope_token },
  #                                variables: { sampleId: @sample.to_global_id.to_s,
  #                                             metadata: { '   key   1    ' => '    value          1     ' } })

  #   assert_nil result['errors'], 'should work and have no errors.'

  #   data = result['data']['updateSampleMetadata']

  #   assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
  #   assert_empty data['errors']
  #   assert_not_empty data['status']
  #   assert_not_empty data['status'][:added]
  #   assert_equal 'key 1', data['status'][:added].first
  #   assert_not_empty data['sample']
  #   assert_not_empty data['sample']['metadata']
  #   assert_not_empty data['sample']['metadata']['key 1']
  #   assert_equal 'value 1', data['sample']['metadata']['key 1']
  # end
end
