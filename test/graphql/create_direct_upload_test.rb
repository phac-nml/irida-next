# frozen_string_literal: true

require 'test_helper'

class CreateDirectUploadTest < ActiveSupport::TestCase
  CREATE_DIRECT_UPLOAD_MUTATION = <<~GRAPHQL
    mutation($filename: String!, $contentType: String!, $checksum: String!, $byteSize: Int!) {
      createDirectUpload(input: {
        filename: $filename,
        contentType: $contentType,
        checksum: $checksum,
        byteSize: $byteSize
      }) {
        directUpload {
          url,
          headers,
          blobId,
          signedBlobId
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
  end

  test 'createDirectUpload mutation should work with valid params and api scope token' do
    result = IridaSchema.execute(CREATE_DIRECT_UPLOAD_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { filename: 'dev.to',
                                              contentType: 'image/jpeg',
                                              checksum: 'asZ3Yzc2Q5iA5eXIgeTJndf',
                                              byteSize: 123 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createDirectUpload']

    assert_not_empty data, 'createDirectUpload should be populated when no authorization errors'
    assert_not_empty data['directUpload']

    assert_equal '{"Content-Type":"image/jpeg"}', data['directUpload']['headers']
    assert_not_empty data['directUpload']['blobId']
    assert_not_empty data['directUpload']['url']
    assert_not_empty data['directUpload']['signedBlobId']
  end

  test 'createDirectUpload mutation should work with valid params and api scope token with uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    result = IridaSchema.execute(CREATE_DIRECT_UPLOAD_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { filename: 'dev.to',
                                              contentType: 'image/jpeg',
                                              checksum: 'asZ3Yzc2Q5iA5eXIgeTJndf',
                                              byteSize: 123 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createDirectUpload']

    assert_not_empty data, 'createDirectUpload should be populated when no authorization errors'
    assert_not_empty data['directUpload']

    assert_equal '{"Content-Type":"image/jpeg"}', data['directUpload']['headers']
    assert_not_empty data['directUpload']['blobId']
    assert_not_empty data['directUpload']['url']
    assert_not_empty data['directUpload']['signedBlobId']
  end

  test 'createDirectUpload mutation should not work with read api scope token' do
    result = IridaSchema.execute(CREATE_DIRECT_UPLOAD_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { filename: 'dev.to',
                                              contentType: 'image/jpeg',
                                              checksum: 'asZ3Yzc2Q5iA5eXIgeTJndf',
                                              byteSize: 123 })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'createDirectUpload mutation should not work with negative bytesize' do
    result = IridaSchema.execute(CREATE_DIRECT_UPLOAD_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { filename: 'dev.to',
                                              contentType: 'image/jpeg',
                                              checksum: 'asZ3Yzc2Q5iA5eXIgeTJndf',
                                              byteSize: -123 })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'byteSize must be greater than 0', error_message
  end

  test 'createDirectUpload mutation should not work with 0 bytesize' do
    result = IridaSchema.execute(CREATE_DIRECT_UPLOAD_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { filename: 'dev.to',
                                              contentType: 'image/jpeg',
                                              checksum: 'asZ3Yzc2Q5iA5eXIgeTJndf',
                                              byteSize: 0 })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'byteSize must be greater than 0', error_message
  end
end
