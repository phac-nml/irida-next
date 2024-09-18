# frozen_string_literal: true

require 'test_helper'

class AttachmentsQueryTest < ActiveSupport::TestCase
  ATTACHMENTS_QUERY = <<~GRAPHQL
    query($puid: ID!, $attachmentFilter: AttachmentFilter, $attachmentOrderBy: AttachmentOrder) {
      sample(puid: $puid) {
        id
        attachments(filter: $attachmentFilter, orderBy: $attachmentOrderBy) {
          nodes {
            id,
            metadata,
            filename,
            byteSize,
            createdAt,
            updatedAt
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_PROJECT_QUERY = <<~GRAPHQL
    query($puid: ID!, $attachmentFilter: AttachmentFilter, $attachmentOrderBy: AttachmentOrder) {
      project(puid: $puid) {
        id
        attachments(filter: $attachmentFilter, orderBy: $attachmentOrderBy) {
          nodes {
            id,
            metadata,
            filename,
            byteSize,
            createdAt,
            updatedAt
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_URL_QUERY = <<~GRAPHQL
    query($puid: ID!) {
      sample(puid: $puid) {
        id
        attachments {
          nodes {
            id,
             filename,
            attachmentUrl,
             createdAt,
            updatedAt
          }
         }
      }
    }
  GRAPHQL

  ATTACHMENTS_METADATA_QUERY = <<~GRAPHQL
    query($puid: ID!) {
      sample(puid: $puid) {
        id
        attachments {
          nodes {
            id,
            metadata(
              keys: ["format"]
            )
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_PAIRED_QUERY = <<~GRAPHQL
    query($first: Int, $samp_puid: ID!) {
      sample(puid: $samp_puid) {
        id
        attachments(first: $first) {
          nodes {
            id,
            metadata
          }
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @sample = samples(:sample1)
    @user_paired = users(:jeff_doe)
    @sample_paired = samples(:sampleB)
  end

  test 'attachment query should work' do
    result = IridaSchema.execute(ATTACHMENTS_QUERY, context: { current_user: @user },
                                                    variables: { puid: @sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'

    assert_not_empty data['attachments']
    assert_not_empty data['attachments']['nodes']

    attachments = data['attachments']['nodes']
    assert_equal 2, attachments.count

    assert_equal 'test_file.fastq', attachments[0]['filename']
    assert_equal 'test_file_A.fastq', attachments[1]['filename']

    assert_equal 2102, attachments[0]['byteSize']
    assert_equal 2101, attachments[1]['byteSize']

    assert_equal 'fastq', attachments[0]['metadata']['format']
    assert_equal 'none', attachments[0]['metadata']['compression']
    assert_equal 'fastq', attachments[1]['metadata']['format']
    assert_equal 'none', attachments[1]['metadata']['compression']
  end

  test 'attachment query on project should work' do
    project = projects(:project1)
    result = IridaSchema.execute(ATTACHMENTS_PROJECT_QUERY, context: { current_user: @user },
                                                            variables: { puid: project.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'

    assert_not_empty data['attachments']
    assert_not_empty data['attachments']['nodes']

    attachments = data['attachments']['nodes']
    assert_equal 2, attachments.count

    assert_equal 'test_file.fastq', attachments[0]['filename']
    assert_equal 'data_export_8.csv', attachments[1]['filename']

    assert_equal 2102, attachments[0]['byteSize']
    assert_equal 84, attachments[1]['byteSize']

    assert_equal 'fastq', attachments[0]['metadata']['format']
    assert_equal 'none', attachments[0]['metadata']['compression']
    assert_equal 'csv', attachments[1]['metadata']['format']
    assert_equal 'none', attachments[1]['metadata']['compression']
  end

  test 'attachment query should work for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    result = IridaSchema.execute(ATTACHMENTS_QUERY, context: { current_user: user, token: },
                                                    variables: { puid: @sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'

    assert_not_empty data['attachments']
    assert_not_empty data['attachments']['nodes']

    attachments = data['attachments']['nodes']
    assert_equal 2, attachments.count

    assert_equal 'test_file.fastq', attachments[0]['filename']
    assert_equal 'test_file_A.fastq', attachments[1]['filename']

    assert_equal 2102, attachments[0]['byteSize']
    assert_equal 2101, attachments[1]['byteSize']

    assert_equal 'fastq', attachments[0]['metadata']['format']
    assert_equal 'none', attachments[0]['metadata']['compression']
    assert_equal 'fastq', attachments[1]['metadata']['format']
    assert_equal 'none', attachments[1]['metadata']['compression']
  end

  test 'attachment query should work with filter' do
    result = IridaSchema.execute(ATTACHMENTS_QUERY, context: { current_user: @user },
                                                    variables: { puid: @sample.puid,
                                                                 attachmentFilter: { filename_end: 'A.fastq' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'

    assert_not_empty data['attachments']
    assert_not_empty data['attachments']['nodes']

    attachments = data['attachments']['nodes']
    assert_equal 1, attachments.count

    assert_equal 'test_file_A.fastq', attachments[0]['filename']

    assert_equal 2101, attachments[0]['byteSize']

    assert_equal 'fastq', attachments[0]['metadata']['format']
    assert_equal 'none', attachments[0]['metadata']['compression']
  end

  test 'attachment query should work with order by' do
    result = IridaSchema.execute(ATTACHMENTS_QUERY, context: { current_user: @user },
                                                    variables: { puid: @sample.puid,
                                                                 attachmentOrderBy: { field: 'filename',
                                                                                      direction: 'asc' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'

    assert_not_empty data['attachments']
    assert_not_empty data['attachments']['nodes']

    attachments = data['attachments']['nodes']
    assert_equal 2, attachments.count

    assert_equal 'test_file.fastq', attachments[0]['filename']
    assert_equal 'test_file_A.fastq', attachments[1]['filename']

    assert_equal 2102, attachments[0]['byteSize']
    assert_equal 2101, attachments[1]['byteSize']

    assert_equal 'fastq', attachments[0]['metadata']['format']
    assert_equal 'none', attachments[0]['metadata']['compression']
    assert_equal 'fastq', attachments[1]['metadata']['format']
    assert_equal 'none', attachments[1]['metadata']['compression']
  end

  test 'attachment url query should work' do
    result = IridaSchema.execute(ATTACHMENTS_URL_QUERY, context: { current_user: @user },
                                                        variables: { puid: @sample.puid })

    # get blob storage file urls
    file1 = @sample.attachments[0].file
    file2 = @sample.attachments[1].file
    file_url1 = Rails.application.routes.url_helpers.rails_blob_url(file1)
    file_url2 = Rails.application.routes.url_helpers.rails_blob_url(file2)

    assert_nil result['errors'], 'should work and have no errors.'

    attachments = result['data']['sample']['attachments']['nodes']
    assert_equal 2, attachments.count

    assert_equal file_url1, attachments[0]['attachmentUrl']
    assert_equal file_url2, attachments[1]['attachmentUrl']
  end

  test 'attachment url query should not work due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)
    result = IridaSchema.execute(ATTACHMENTS_URL_QUERY, context: { current_user: user, token: },
                                                        variables: { puid: @sample.puid })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'An object of type Sample was hidden due to permissions', error_message
  end

  test 'attachment metadata delimit query should work' do
    result = IridaSchema.execute(ATTACHMENTS_METADATA_QUERY, context: { current_user: @user },
                                                             variables: { puid: @sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    attachments = result['data']['sample']['attachments']['nodes']
    metadata1 = attachments[0]['metadata']
    metadata2 = attachments[1]['metadata']

    assert_equal 'fastq', metadata1['format'], "should have requested 'format'"
    assert_equal 'fastq', metadata2['format'], "should have requested 'format'"

    assert_nil metadata1['compression'], 'should not have field that was not requested'
    assert_nil metadata2['compression'], 'should not have field that was not requested'
  end

  test 'attachment paired query should work' do
    result = IridaSchema.execute(
      ATTACHMENTS_PAIRED_QUERY,
      context: { current_user: @user_paired },
      variables: { first: 2, samp_puid: @sample_paired.puid }
    )

    assert_nil result['errors'], 'should work and have no errors.'

    attachment1 = result['data']['sample']['attachments']['nodes'][0]
    attachment2 = result['data']['sample']['attachments']['nodes'][1]
    metadata1 = attachment1['metadata']
    metadata2 = attachment2['metadata']

    assert_equal 'forward', metadata1['direction']
    assert_equal 'reverse', metadata2['direction']

    assert_equal 'pe', metadata1['type']
    assert_equal 'pe', metadata2['type']

    # check they reference each other
    assert_equal attachment1['id'], "gid://irida/Attachment/#{metadata2['associated_attachment_id']}"
    assert_equal attachment2['id'], "gid://irida/Attachment/#{metadata1['associated_attachment_id']}"
  end
end
