# frozen_string_literal: true

require 'test_helper'

# good case
# bad case
# already attached case

class AttachFilesToSampleTest < ActiveSupport::TestCase
  ATTACH_FILES_TO_SAMPLE_MUTATION = <<~GRAPHQL
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

  def setup
    @user = users(:jeff_doe)
    @api_scope_token = personal_access_tokens(:jeff_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:jeff_doe_valid_read_pat)
  end

  test 'attachFilesToSample mutation should work with valid params and api scope token' do
    sample = samples(:sampleJeff)
    blob_file = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { 'eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47' => :success } # rubocop:disable Layout/LineLength
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

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
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

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_equal 1, sample.attachments.count
    data = result['data']['attachFilesToSample']
    assert_equal 0, data['errors'].count, 'should work and have no errors.'
    expected_status = { 'eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47' => :success } # rubocop:disable Layout/LineLength
    assert_equal expected_status, data['status']

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_equal 1, sample.attachments.count # should not increase
    data = result['data']['attachFilesToSample']
    expected_status = { 'eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47' => :error } # rubocop:disable Layout/LineLength
    assert_equal expected_status, data['status']
    assert_equal 1, data['errors'].count, 'shouldn\'t work and have errors.'
    expected_error = 'eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47["File checksum matches existing file"]' # rubocop:disable Layout/LineLength
    assert_equal expected_error, data['errors'][0]
    assert_equal :error, data['status']['eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47'] # rubocop:disable Layout/LineLength
  end

  test 'attachFilesToSample mutation attach file with same checksum' do
    sample = samples(:sampleJeff)
    # These files have the same md5 sum
    blob_file_a = active_storage_blobs(:attachment_md5_a_test_blob)
    blob_file_b = active_storage_blobs(:attachment_md5_b_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id],
                                              sampleId: sample.to_global_id.to_s })

                                              assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { 'eyJfcmFpbHMiOnsiZGF0YSI6MzAzNDg0NDkzLCJwdXIiOiJibG9iX2lkIn19--4487c7e7ecee462e14bba9e588d90a542d02cc05' => :success } # rubocop:disable Layout/LineLength
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    assert_equal 1, sample.attachments.count
    assert_equal 'md5_a', sample.attachments[0].filename.to_s

    # Second file
    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_b.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = { 'eyJfcmFpbHMiOnsiZGF0YSI6MjAwNTgzMjQ4LCJwdXIiOiJibG9iX2lkIn19--a38a64c5562aacf1978595e0c9ebaa3228b5fc94' => :error } # rubocop:disable Layout/LineLength
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']
    assert_equal ['eyJfcmFpbHMiOnsiZGF0YSI6MjAwNTgzMjQ4LCJwdXIiOiJibG9iX2lkIn19--a38a64c5562aacf1978595e0c9ebaa3228b5fc94["File checksum matches existing file"]'], # rubocop:disable Layout/LineLength
                 data['errors']
    assert_equal 1, sample.attachments.count
  end

  test 'attachFilesToSample mutation attach 2 files at once' do
    sample = samples(:sampleJeff)
    blob_file_a = active_storage_blobs(:attachment_attach_files_to_sample_test_blob)
    blob_file_b = active_storage_blobs(:attachment_attach_files_to_sample_b_test_blob)

    assert_equal 0, sample.attachments.count

    result = IridaSchema.execute(ATTACH_FILES_TO_SAMPLE_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [blob_file_a.signed_id, blob_file_b.signed_id],
                                              sampleId: sample.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['attachFilesToSample']

    assert_not_empty data, 'attachFilesToSample should be populated when no authorization errors'
    expected_status = {
      'eyJfcmFpbHMiOnsiZGF0YSI6ODkzNjcyOTMyLCJwdXIiOiJibG9iX2lkIn19--110d021a6b4bd25adabc846a8c05799511670d47' => :success, # rubocop:disable Layout/LineLength
      'eyJfcmFpbHMiOnsiZGF0YSI6MTAxODg3MDQ0MiwicHVyIjoiYmxvYl9pZCJ9fQ==--bdb9957bb41aa3b8671863fe711a998f8cd4df59' => :success # rubocop:disable Layout/LineLength
    }
    assert_equal expected_status, data['status']
    assert_not_empty data['sample']

    assert_equal 2, sample.attachments.count

    # check that filename matches
    assert_equal 'afts.fastq', sample.attachments[0].filename.to_s
    assert_equal 'afts_b.fastq', sample.attachments[1].filename.to_s
  end
end
