# frozen_string_literal: true

require 'test_helper'

class AttachFilesToSampleTest < ActiveSupport::TestCase
  ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION = <<~GRAPHQL
    mutation($files: [String!]!, $sampleId: ID!) {
      attachFilesToSample(input: { files: $files, sampleId: $sampleId,
      })
      {
        sample{id},
        status,
        errors
      }
    }
  GRAPHQL

  ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_PUID_MUTATION = <<~GRAPHQL
    mutation($files: [String!]!, $samplePuid: ID!) {
      attachFilesToSample(input: { files: $files, samplePuid: $samplePuid,
      })
      {
        sample{id},
        status,
        errors
      }
    }
  GRAPHQL

  def setup
    @user = users(:jeff_doe)
    @api_scope_token = personal_access_tokens(:jeff_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:jeff_doe_valid_read_pat)
  end

  test 'attachFilesToSample mutation should work with valid params, global id, and api scope token' do
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']

    assert_equal 1, sample.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', sample.attachments[0].filename.to_s
  end

  test 'attachFilesToSample mutation should work with valid params, puid, and api scope token' do
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              samplePuid: sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']

    assert_equal 1, sample.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', sample.attachments[0].filename.to_s
  end

  test 'attachFilesToSample mutation should work with valid params, puid, and api scope token for uploader access level' do # rubocop:disable Layout/LineLength
    user = users(:projectJeff_bot)
    token = personal_access_tokens(:projectJeff_bot_account_valid_pat)
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_PUID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { files: [blob_file.signed_id],
                                              samplePuid: sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']

    assert_equal 1, sample.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', sample.attachments[0].filename.to_s
  end

  test 'attachFilesToSample mutation should not work with read api scope token' do
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    assert_equal 0, sample.attachments.count

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'attachFilesToSample mutation attach same file to sample error' do
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_equal 1, sample.attachments.count
    data = result['data']['attachFilesToSample']
    assert_equal 0, data['errors'].count, 'should work and have no errors.'
    expected_status = { blob_file.signed_id => :success }
    assert_equal expected_status, data['status']

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_equal 1, sample.attachments.count # should not increase
    data = result['data']['attachFilesToSample']
    expected_status = { blob_file.signed_id => :error }
    assert_equal expected_status, data['status']
    assert_equal 1, data['errors'].count, 'shouldn\'t work and have errors.'
    expected_error = { blob_file.signed_id => ['File checksum matches existing file'] }
    assert_equal expected_error, data['errors']
    assert_equal :error, data['status'][blob_file.signed_id]
  end

  test 'attachFilesToSample mutation attach file with same content but different names' do
    sample = samples(:sampleJeff)
    # These files have the same md5 sum
    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_b = active_storage_blobs(:attachment_md5_b_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    assert_equal 1, sample.attachments.count
    assert_equal 'md5_a', sample.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_b.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_b.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    sample.reload
    assert_equal 2, sample.attachments.count
    assert_equal 'md5_b', sample.attachments[1].filename.to_s
  end

  test 'attachFilesToSample mutation attach file with same checksum and same names' do
    sample = samples(:sampleJeff)
    # These files have the same md5 sum
    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_a2 = active_storage_blobs(:attachment_md5_a_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    assert_equal 1, sample.attachments.count
    assert_equal 'md5_a', sample.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a2.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_a2.signed_id => :error }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    expected_error = { blob_file_a2.signed_id => ['File checksum matches existing file'] }
    assert_equal expected_error, data['errors']
    assert_equal 1, sample.attachments.count
  end

  test 'attachFilesToSample mutation attach file with different checksum and same names' do
    sample = samples(:sampleJeff)
    # These files have the same md5 sum
    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_b = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    blob_file_b.filename = 'md5_a'
    blob_file_b.save
    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_a.signed_id => :success }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    assert_equal 1, sample.attachments.count
    assert_equal 'md5_a', sample.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_b.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { blob_file_b.signed_id => :error }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    expected_error = { blob_file_b.signed_id => ['File checksum matches existing file'] }
    assert_equal expected_error, data['errors']
    assert_equal 1, sample.attachments.count
  end

  test 'attachFilesToSample mutation attach 2 files at once' do
    sample = samples(:sampleJeff)
    blob_file_a = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)
    blob_file_b = active_storage_blobs(:attachment_attach_files_to_sample_b_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id, blob_file_b.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = {
      blob_file_a.signed_id => :success,
      blob_file_b.signed_id => :success
    }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']

    assert_equal 2, sample.attachments.count

    # check that filenames matches
    assert [sample.attachments[0].filename.to_s, sample.attachments[1].filename.to_s].include? 'afts.fastq'
    assert [sample.attachments[0].filename.to_s, sample.attachments[1].filename.to_s].include? 'afts_b.fastq'
  end

  test 'attachFilesToSample mutation should not work with invalid blob id' do
    sample = samples(:sampleJeff)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: ['NAN'],
                                              sampleId: sample.to_global_id.to_s })

    assert_not_nil result['data']['attachFilesToSample']['errors'], 'shouldn\'t work and have errors.'

    assert_equal 0, sample.attachments.count

    expected_error = { 'query' => ['mismatched digest: Invalid blob id'] }
    actual_error = result['data']['attachFilesToSample']['errors']

    assert_equal actual_error, expected_error
  end

  test 'attachFilesToSample mutation should not work with invalid sample id' do
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_raises RuntimeError do
      IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_BY_SAMPLE_ID_MUTATION,
                          context: { current_user: @user, token: @api_scope_token },
                          variables: { files: [blob_file.signed_id],
                                       sampleId: 'this is not a valid sample id' })
    end
  end
end
