# frozen_string_literal: true

require 'test_helper'

class BulkUpdateSampleMetadataMutationTest < ActiveSupport::TestCase
  UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION = <<~GRAPHQL
    mutation($metadata: JSON!, $projectId: ID!) {
      bulkUpdateSampleMetadata(input: { metadata: $metadata, projectId: $projectId }) {
        overallStatus,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_PROJECT_PUID_MUTATION = <<~GRAPHQL
    mutation($metadata: JSON!, $projectPuid: ID!) {
      bulkUpdateSampleMetadata(input: { metadata: $metadata, projectPuid: $projectPuid }) {
        overallStatus,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION = <<~GRAPHQL
    mutation($metadata: JSON!, $groupId: ID!) {
      bulkUpdateSampleMetadata(input: { metadata: $metadata, groupId: $groupId }) {
        overallStatus,
        status,
        errors {
          path
          message
        }
      }
    }
  GRAPHQL

  UPDATE_SAMPLE_METADATA_BY_GROUP_PUID_MUTATION = <<~GRAPHQL
    mutation($metadata: JSON!, $groupPuid: ID!) {
      bulkUpdateSampleMetadata(input: { metadata: $metadata, groupPuid: $groupPuid }) {
        overallStatus,
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

  test 'valid params, project puid, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectPuid: @project2.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal 3, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample4.name][:added]
    assert_equal ['newmetadatafield3'], data['status'][@sample5.puid][:added]

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'valid params, project id, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal 3, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample4.name][:added]
    assert_equal ['newmetadatafield3'], data['status'][@sample5.puid][:added]

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'valid params, group puid, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupPuid: @group1.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal 3, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample4.name][:added]
    assert_equal ['newmetadatafield3'], data['status'][@sample5.puid][:added]

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'valid params, group id, and api scope token' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal 3, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample4.name][:added]
    assert_equal ['newmetadatafield3'], data['status'][@sample5.puid][:added]

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2' }, @sample4.reload.metadata)
    assert_equal({ 'newmetadatafield3' => 'value3' }, @sample5.reload.metadata)
  end

  test 'group level with partial success' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
                         'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]

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

  test 'project level with partial success' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
                         'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
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

  test 'group level with no success' do
    metadata_payload = {
      'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
      'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' }
    }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['overallStatus']
    assert_empty data['status']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
  end

  test 'project level with no success' do
    metadata_payload = {
      'INVALID_NAME_1' => { 'newmetadatafield2' => 'value2' },
      'INVALID_NAME_2' => { 'newmetadatafield3' => 'value3' }
    }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['overallStatus']
    assert_empty data['status']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_1')
    }
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: 'INVALID_NAME_2')
    }
  end

  test 'valid params and api scope token with uploader level at project level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)

    assert @sample1.metadata.empty?
    assert @sample2.metadata.empty?
    metadata_payload = { @sample1.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample2.name => { 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project1.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal 2, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample1.to_global_id.to_s][:added]
    assert_includes(data['status'][@sample2.name][:added], 'newmetadatafield2')
    assert_includes(data['status'][@sample2.name][:added], 'newmetadatafield3')

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample1.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' }, @sample2.reload.metadata)
  end

  test 'empty metadata' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => {} }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield1'], data['status'][@sample3.to_global_id.to_s][:added]
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample4.name)
    }
    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
  end

  test 'valid params and read api scope token' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'valid params and no permission at project level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:jane_doe)
    api_scope_token = personal_access_tokens(:jane_doe_valid_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_sample_metadata?',
                        name: @project2.name), error_message
  end

  test 'valid params and no permission at group level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:jane_doe)
    api_scope_token = personal_access_tokens(:jane_doe_valid_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t(:'action_policy.policy.group.update_sample_metadata?', name: @group1.name), error_message
  end

  test 'valid params but with expired token for uploader access level at group level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_expired_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'valid params but with expired token for uploader access level at project level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_expired_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'invalid sample gid' do
    invalid_gid = @sample3.to_global_id.to_s[0...-1] # remove last char of id
    metadata_payload = { invalid_gid => { 'newmetadatafield1' => 'value1' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })
    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['overallStatus']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found',
                          sample_identifier: IridaSchema.parse_gid(invalid_gid, { expected_type: Sample }).model_id)
    }
  end

  test 'invalid JSON formatting' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: 'metadata_payload',
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data
    assert_not_empty data['errors']

    expected_error = [{
      'path' => ['metadata'],
      'message' => "JSON data is not formatted correctly. unexpected character: 'metadata_payload' at line 1 column 1"
    }]
    assert_equal expected_error, data['errors']
  end

  test 'nested metadata' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.puid => { newmetadata: { 'newmetadatafield1' => 'value1' } } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['overallStatus']

    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.nested_metadata', sample_name: @sample3.name, key: 'newmetadata')
    }
    assert @sample3.reload.metadata.empty?
  end

  test 'should convert upper case characters in keys to lower case and values to strings' do
    assert @sample1.metadata.empty?
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    assert @sample5.metadata.empty?
    metadata_payload = { @sample1.name => { 'newMetadataField1' => 'Value1' },
                         @sample3.puid => { 'NEWMETADATAFIELD2' => true },
                         @sample4.to_global_id.to_s => { 'NEWMETADATAFIELD3' => Date.parse('2024-03-11') },
                         @sample5.name => { 'newmetadatafield4' => nil } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful', data['overallStatus']
    assert_equal 3, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample1.name][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample3.puid][:added]
    assert_equal ['newmetadatafield3'], data['status'][@sample4.to_global_id.to_s][:added]

    assert_equal({ 'newmetadatafield1' => 'Value1' }, @sample1.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'true' }, @sample3.reload.metadata)
    assert_equal({ 'newmetadatafield3' => '2024-03-11' }, @sample4.reload.metadata)
    assert @sample5.reload.metadata.empty?
  end

  test 'should strip leading/trailing whitespaces and convert multiple inner whitespaces into single whitespace' do
    assert @sample1.metadata.empty?
    assert @sample2.metadata.empty?
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?

    metadata_payload = {
      @sample1.puid => { '    newmetadatafield1            ' => '        newvalue1     ' },
      @sample2.to_global_id.to_s => { 'newmetadatafield2              ' => '           newvalue2' },
      @sample3.puid => { '      new       metadatafield3              ' => '           new value     3    ' },
      @sample4.name => { '      new       metadatafield     4             ' => '           new value 4    ' }
    }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful', data['overallStatus']
    assert_equal 4, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample1.puid][:added]
    assert_equal ['newmetadatafield2'], data['status'][@sample2.to_global_id.to_s][:added]
    assert_equal ['new metadatafield3'], data['status'][@sample3.puid][:added]
    assert_equal ['new metadatafield 4'], data['status'][@sample4.name][:added]

    assert_equal({ 'newmetadatafield1' => 'newvalue1' }, @sample1.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'newvalue2' }, @sample2.reload.metadata)
    assert_equal({ 'new metadatafield3' => 'new value 3' }, @sample3.reload.metadata)
    assert_equal({ 'new metadatafield 4' => 'new value 4' }, @sample4.reload.metadata)
  end

  test 'cannot update shared sample without proper shared access' do
    token = personal_access_tokens(:sample_actions_doe_valid_pat)
    group = groups(:group_sample_actions)
    user = users(:sample_actions_doe)
    sample = samples(:sample71)

    metadata_payload = { sample.puid => { 'newmetadatafield1' => 'value1' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_PUID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadata: metadata_payload,
                                              groupPuid: group.puid })
    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['overallStatus']
    assert_empty data['status']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found', sample_identifier: sample.puid)
    }
  end

  test 'can update shared sample with proper shared access' do
    token = personal_access_tokens(:sample_actions_doe_valid_pat)
    group = groups(:group_sample_actions)
    user = users(:sample_actions_doe)
    sample = samples(:sample70)

    assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample.metadata)
    metadata_payload = { sample.puid => { 'newmetadatafield1' => 'value1' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadata: metadata_payload,
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal ['newmetadatafield1'], data['status'][sample.puid][:added]

    assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'newmetadatafield1' => 'value1' },
                 sample.reload.metadata)
  end

  test 'invalid group id' do
    invalid_gid = @group1.to_global_id.to_s[0...-1] # remove last char of id
    metadata_payload = { @sample3.puid => { 'newmetadatafield1' => 'value1' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: invalid_gid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']

    expected_error = [{
      'path' => ['group'],
      'message' => "not found by provided ID or PUID: #{invalid_gid}"
    }]
    assert_equal expected_error, data['errors']
  end

  test 'invalid project id' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => { 'newmetadatafield2' => 'value2' },
                         @sample5.puid => { 'newmetadatafield3' => 'value3' } }
    invalid_gid = @project2.to_global_id.to_s[0...-1] # remove last char of id
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: invalid_gid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']
    expected_error = [{
      'path' => ['project'],
      'message' => "not found by provided ID or PUID: #{invalid_gid}"
    }]
    assert_equal expected_error, data['errors']
  end

  test 'partial update where a field is provided the same value to update at project level' do
    project = projects(:project37)
    sample = samples(:sample43)

    assert_equal({ 'insdc_accession' => 'ERR86724108', 'country' => 'Canada' },
                 sample.metadata)
    metadata_payload = { sample.puid => { insdc_accession: 'ERR86724108', country: 'newcountry',
                                          newmetadatafield: 'newvalue' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: project.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield'], data['status'][sample.puid][:added]
    assert_equal ['country'], data['status'][sample.puid][:updated]
    assert_equal ['insdc_accession'], data['status'][sample.puid][:unchanged]

    expected_error = [{
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_metadata_fields_unchanged',
                          sample_name: sample.puid, metadata_fields: 'insdc_accession')

    }]
    assert_equal expected_error, data['errors']
    assert_equal({ 'country' => 'newcountry', 'insdc_accession' => 'ERR86724108', 'newmetadatafield' => 'newvalue' },
                 sample.reload.metadata)
  end

  test 'partial update where a field is provided the same value to update at group level' do
    group = groups(:group_sixteen)
    sample = samples(:sample43)

    assert_equal({ 'insdc_accession' => 'ERR86724108', 'country' => 'Canada' },
                 sample.metadata)
    metadata_payload = { sample.puid => { insdc_accession: 'ERR86724108', country: 'newcountry',
                                          newmetadatafield: 'newvalue' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield'], data['status'][sample.puid][:added]
    assert_equal ['country'], data['status'][sample.puid][:updated]
    assert_equal ['insdc_accession'], data['status'][sample.puid][:unchanged]

    expected_error = [{
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_metadata_fields_unchanged',
                          sample_name: sample.puid, metadata_fields: 'insdc_accession')

    }]
    assert_equal expected_error, data['errors']
    assert_equal({ 'country' => 'newcountry', 'insdc_accession' => 'ERR86724108', 'newmetadatafield' => 'newvalue' },
                 sample.reload.metadata)
  end

  test 'update where a field is provided the same value to update at group level' do
    group = groups(:group_sixteen)
    sample43 = samples(:sample43)
    sample44 = samples(:sample44)

    assert_equal({ 'insdc_accession' => 'ERR86724108', 'country' => 'Canada' },
                 sample43.metadata)
    assert_equal({ 'insdc_accession' => 'ERR31551163', 'country' => 'Moldova' },
                 sample44.metadata)
    metadata_payload = { sample43.puid => { insdc_accession: 'ERR86724108', country: 'newcountry',
                                            newmetadatafield1: 'newvalue1' },
                         sample44.name => { insdc_accession: 'ERR31551163', country: 'Moldova',
                                            newmetadatafield2: 'newvalue2' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal ['newmetadatafield1'], data['status'][sample43.puid][:added]
    assert_equal ['country'], data['status'][sample43.puid][:updated]
    assert_equal ['insdc_accession'], data['status'][sample43.puid][:unchanged]
    assert_equal ['newmetadatafield2'], data['status'][sample44.name][:added]
    assert_includes(data['status'][sample44.name][:unchanged], 'country')
    assert_includes(data['status'][sample44.name][:unchanged], 'insdc_accession')

    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_metadata_fields_unchanged',
                          sample_name: sample43.puid, metadata_fields: 'insdc_accession')
    }

    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_metadata_fields_unchanged',
                          sample_name: sample44.name, metadata_fields: %w[insdc_accession country].join(', '))

    }
    assert_equal({ 'country' => 'newcountry', 'insdc_accession' => 'ERR86724108', 'newmetadatafield1' => 'newvalue1' },
                 sample43.reload.metadata)
    assert_equal({ 'country' => 'Moldova', 'insdc_accession' => 'ERR31551163', 'newmetadatafield2' => 'newvalue2' },
                 sample44.reload.metadata)
  end

  test 'can delete metadata field' do
    group = groups(:group_sixteen)
    sample43 = samples(:sample43)
    sample44 = samples(:sample44)

    assert_equal({ 'insdc_accession' => 'ERR86724108', 'country' => 'Canada' },
                 sample43.metadata)
    assert_equal({ 'insdc_accession' => 'ERR31551163', 'country' => 'Moldova' },
                 sample44.metadata)
    metadata_payload = { sample43.puid => { country: '' },
                         sample44.name => { insdc_accession: '' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['overallStatus']
    assert_equal ['country'], data['status'][sample43.puid][:deleted]
    assert_equal ['insdc_accession'], data['status'][sample44.name][:deleted]

    assert_equal({ 'insdc_accession' => 'ERR86724108' }, sample43.reload.metadata)
    assert_equal({ 'country' => 'Moldova' }, sample44.reload.metadata)
  end

  test 'empty metadata value when field does not exist' do
    assert @sample3.metadata.empty?
    assert @sample4.metadata.empty?
    metadata_payload = { @sample3.puid => { 'newmetadatafield1' => '' },
                         @sample4.name => { 'newmetadatafield2' => nil } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadata: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['bulkUpdateSampleMetadata']
    assert_not_empty data, 'bulkUpdateSampleMetadata should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_equal 'successful with errors', data['overallStatus']
    assert_equal 2, data['status'].keys.count
    assert_equal ['newmetadatafield1'], data['status'][@sample3.puid][:not_found]
    assert_equal ['newmetadatafield2'], data['status'][@sample4.name][:not_found]
    assert @sample3.reload.metadata.empty?
    assert @sample4.reload.metadata.empty?
  end
end
