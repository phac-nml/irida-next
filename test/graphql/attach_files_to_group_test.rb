# frozen_string_literal: true

require 'test_helper'

class AttachFilesToGroupTest < ActiveSupport::TestCase
  ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION = <<~GRAPHQL
    mutation($files: [String!]!, $groupId: ID!) {
      attachFilesToGroup(input: { files: $files, groupId: $groupId,
      })
      {
        group{id},
        status,
        errors{
          path
          message
        }
      }
    }
  GRAPHQL

  ATTACH_FILES_TO_GROUP_BY_GROUP_PUID_MUTATION = <<~GRAPHQL
    mutation($files: [String!]!, $groupPuid: ID!) {
      attachFilesToGroup(input: { files: $files, groupPuid: $groupPuid,
      })
      {
        group{id},
        status,
        errors{
          path
          message
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:jeff_doe)
    @api_scope_token = personal_access_tokens(:jeff_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:jeff_doe_valid_read_pat)
  end

  test 'attachFilesToGroup mutation should work with valid params, global id, and api scope token' do
    group = groups(:group_jeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']

    assert_equal 1, group.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', group.attachments[0].filename.to_s
  end

  test 'attachFilesToGroup mutation should work with valid params, puid, and api scope token' do
    group = groups(:group_jeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupPuid: group.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']

    assert_equal 1, group.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', group.attachments[0].filename.to_s
  end

  test 'attachFilesToGroup mutation should work with valid params, puid, and api scope token for uploader access level' do # rubocop:disable Layout/LineLength
    user = users(:groupJeff_bot)
    token = personal_access_tokens(:groupJeff_bot_account_valid_pat)
    group = groups(:group_jeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_PUID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { files: [blob_file.signed_id],
                                              groupPuid: group.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']

    assert_equal 1, group.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', group.attachments[0].filename.to_s
  end

  test 'attachFilesToGroup mutation should not work with read api scope token' do
    group = groups(:group_jeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    assert_equal 0, group.attachments.count

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'attachFilesToGroup mutation attach same file to group error' do
    group = groups(:group_jeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_equal 1, group.attachments.count
    data = result['data']['attachFilesToGroup']
    assert_equal 0, data['errors'].count, 'should work and have no errors.'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_equal 1, group.attachments.count # should not increase
    data = result['data']['attachFilesToGroup']
    expected_status = { blob_file.signed_id => :error }
    assert_equal expected_status, data['status']
    assert_equal 1, data['errors'].count, 'shouldn\'t work and have errors.'
    expected_error = [
      { 'path' => ['attachment', blob_file.signed_id],
        'message' => 'checksum matches existing file' }
    ]
    assert_equal expected_error, data['errors']
    assert_equal :error, data['status'][blob_file.signed_id]
  end

  test 'attachFilesToGroup mutation attach file with same checksum but different names' do
    group = groups(:group_jeff)

    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_b = active_storage_blobs(:attachment_md5_b_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    assert_equal 1, group.attachments.count
    assert_equal 'md5_a', group.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_b.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_b.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    assert_equal 2, group.attachments.count
  end

  test 'attachFilesToGroup mutation attach file with same checksum and same names' do
    group = groups(:group_jeff)

    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_a2 = active_storage_blobs(:attachment_md5_a_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    assert_equal 1, group.attachments.count
    assert_equal 'md5_a', group.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a2.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_a2.signed_id => :error }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    expected_error = [
      { 'path' => ['attachment', blob_file_a2.signed_id],
        'message' => 'checksum matches existing file' }
    ]
    assert_equal expected_error, data['errors']
    assert_equal 1, group.attachments.count
  end

  test 'attachFilesToGroup mutation attach file with different checksum and same names' do
    group = groups(:group_jeff)

    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_b = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    # match blob_file_b.filename to blob_file_a.filename
    blob_file_b.filename = 'md5_a'
    blob_file_b.save
    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    assert_equal 1, group.attachments.count
    assert_equal 'md5_a', group.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_b.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = { blob_file_b.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']
    group.reload
    assert_equal 2, group.attachments.count
    assert_equal 'md5_a', group.attachments[1].filename.to_s
  end

  test 'attachFilesToGroup mutation attach 2 files at once' do
    group = groups(:group_jeff)
    blob_file_a = active_storage_blobs(:attachment_attach_files_to_object_test_blob)
    blob_file_b = active_storage_blobs(:attachment_attach_files_to_object_b_test_blob)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id, blob_file_b.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToGroup']

    assert_not_empty data, 'attachFilesToGroup should be populated when no authorization errors'
    expected_status = {
      blob_file_a.signed_id => :success,
      blob_file_b.signed_id => :success
    }
    assert_equal expected_status, data['status']
    assert_not_empty data['group']

    assert_equal 2, group.attachments.count

    # check that filenames matches
    assert [group.attachments[0].filename.to_s,
            group.attachments[1].filename.to_s].include? 'afts.fastq'
    assert [group.attachments[0].filename.to_s,
            group.attachments[1].filename.to_s].include? 'afts_b.fastq'
  end

  test 'attachFilesToGroup mutation should not work with invalid blob id' do
    group = groups(:group_jeff)

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: ['NAN'],
                                              groupId: group.to_global_id.to_s })

    assert_not_nil result['data']['attachFilesToGroup']['errors'], 'shouldn\'t work and have errors.'

    assert_equal 0, group.attachments.count

    expected_error = [
      { 'path' => %w[blob_id NAN],
        'message' => 'Blob id could not be processed. Blob id is invalid or file is missing.' },
      { 'path' => %w[group base],
        'message' => 'mismatched digest: Invalid blob id' }
    ]
    actual_error = result['data']['attachFilesToGroup']['errors']

    assert_equal expected_error, actual_error
  end

  test 'attachFilesToGroup mutation should not work with blob missing file' do
    group = groups(:group_jeff)
    # blob_file_missing = active_storage_blobs(:attachment_attach_files_to_object_test_blob)
    blob_file_missing = ActiveStorage::Blob.create_before_direct_upload!(
      filename: 'missing.file', byte_size: 404, checksum: 'Y33CgI35hFoI6p+WBXYl+A=='
    )

    assert_equal 0, group.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_missing.signed_id],
                                              groupId: group.to_global_id.to_s })

    assert_not_nil result['data']['attachFilesToGroup']['errors'], 'shouldn\'t work and have errors.'

    assert_equal 0, group.attachments.count

    expected_error = [
      { 'path' => ['blob_id', blob_file_missing.signed_id],
        'message' => 'Blob id could not be processed. Blob id is invalid or file is missing.' },
      { 'path' => %w[group base],
        'message' => 'ActiveStorage::FileNotFoundError: Blob is empty, no file found.' }
    ]

    actual_error = result['data']['attachFilesToGroup']['errors']

    assert_equal expected_error, actual_error
  end

  test 'attachFilesToGroup mutation should not work with invalid group id' do
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    group = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                  context: { current_user: @user, token: @api_scope_token },
                                  variables: { files: [blob_file.signed_id],
                                               groupId: 'this is not a valid group id' })
    expected_error = { 'message' => 'this is not a valid group id is not a valid IRIDA Next ID.',
                       'locations' => [{ 'line' => 2, 'column' => 3 }], 'path' => ['attachFilesToGroup'] }
    assert_equal expected_error, group['errors'][0]
  end

  test 'attachFilesToGroup mutation should not work with invalid group gid' do
    blob_file = active_storage_blobs(:attachment_attach_files_to_object_test_blob)

    result = IridaSchema.execute(ATTACH_FILES_TO_GROUP_BY_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              groupId: 'gid://irida/Group/doesnotexist' })
    expected_error = { 'message' => 'not found by provided ID or PUID', 'path' => ['group'] }
    assert_equal expected_error, result['data']['attachFilesToGroup']['errors'][0]
  end
end
