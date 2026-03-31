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

  test 'valid params, project puid, and api scope token' do
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
    assert_equal 'successful', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

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
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

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
                                 variables: { metadataPayload: metadata_payload,
                                              groupPuid: @group1.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample3.to_global_id.to_s)
    assert_includes(data['samples'], @sample4.name)
    assert_includes(data['samples'], @sample5.puid)

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

  test 'project level with partial success' do
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

  test 'group level with no success' do
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

  test 'project level with no success' do
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

  test 'valid params and api scope token with uploader level at project level' do
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
    assert_equal 'successful', data['status']
    assert_equal 2, data['samples'].count
    assert_includes(data['samples'], @sample1.to_global_id.to_s)
    assert_includes(data['samples'], @sample2.name)

    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample1.reload.metadata)
    assert_equal({ 'newmetadatafield2' => 'value2', 'newmetadatafield3' => 'value3' }, @sample2.reload.metadata)
  end

  test 'empty metadata' do
    assert @sample3.metadata.empty?
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' },
                         @sample4.name => {} }

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
      'message' => I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample4.name)
    }
    assert_equal({ 'newmetadatafield1' => 'value1' }, @sample3.reload.metadata)
  end

  test 'valid params and read api scope token' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
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
                                 variables: { metadataPayload: metadata_payload,
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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t(:'action_policy.policy.group.update_sample_metadata?', name: @group1.name), error_message
  end

  test 'valid params due but with expired token for uploader access level at group level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_expired_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'valid params due but with expired token for uploader access level at project level' do
    metadata_payload = { @sample3.to_global_id.to_s => { 'newmetadatafield1' => 'value1' } }
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_expired_pat)

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'invalid gid' do
    invalid_gid = @sample3.to_global_id.to_s[0...-1] # remove last char of id
    metadata_payload = { invalid_gid => { 'newmetadatafield1' => 'value1' } }

    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: metadata_payload,
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['status']
    assert_includes data['errors'], {
      'path' => ['sample'],
      'message' => I18n.t('services.samples.metadata.bulk_update.sample_not_found',
                          sample_identifier: IridaSchema.parse_gid(invalid_gid, { expected_type: Sample }).model_id)
    }
  end

  test 'invalid JSON formatting' do
    result = IridaSchema.execute(UPDATE_SAMPLE_METADATA_BY_PROJECT_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { metadataPayload: 'metadata_payload',
                                              projectId: @project2.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['status']

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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful', data['status']
    assert_equal 3, data['samples'].count
    assert_includes(data['samples'], @sample1.name)
    assert_includes(data['samples'], @sample3.puid)
    assert_includes(data['samples'], @sample4.to_global_id.to_s)

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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: @group1.to_global_id.to_s })

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'successful', data['status']
    assert_equal 4, data['samples'].count
    assert_includes(data['samples'], @sample1.puid)
    assert_includes(data['samples'], @sample2.to_global_id.to_s)
    assert_includes(data['samples'], @sample3.puid)
    assert_includes(data['samples'], @sample4.name)

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
                                 variables: { metadataPayload: metadata_payload,
                                              groupPuid: group.puid })
    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_equal 'unsuccessful', data['status']
    assert_empty data['samples']
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
                                 variables: { metadataPayload: metadata_payload,
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['updateSampleMetadata']
    assert_not_empty data, 'updateSampleMetadata should be populated when no authorization errors'
    assert_empty data['errors']
    assert_equal 'successful', data['status']
    assert_equal [sample.puid], data['samples']

    assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'newmetadatafield1' => 'value1' },
                 sample.reload.metadata)
  end
end
