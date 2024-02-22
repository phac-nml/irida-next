# frozen_string_literal: true

require 'test_helper'

class AttachmentsQueryTest < ActiveSupport::TestCase
  ATTACHMENTS_QUERY = <<~GRAPHQL
    query($first: Int) {
      samples(first: $first) {
        nodes {
          id
          attachments {
            edges {
              node {
                id,
                metadata,
                filename,
                byteSize
              }
            }
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_URL_QUERY = <<~GRAPHQL
    query($first: Int) {
      samples(first: $first) {
        nodes {
          id
          attachments {
            edges {
              node {
                id,
                filename,
                attachmentUrl
              }
            }
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_METADATA_QUERY = <<~GRAPHQL
    query($first: Int) {
      samples(first: $first) {
        nodes {
          id
          attachments {
            edges {
              node {
                id,
                metadata(
                  keys: ["format"]
                )
              }
            }
          }
        }
      }
    }
  GRAPHQL

  ATTACHMENTS_PAIRED_QUERY = <<~GRAPHQL
    query($first: Int, $samp_id: ID!) {
      node(id: $samp_id) {
        ... on Sample{
          id
          attachments(first: $first) {
            edges {
              node {
                id,
                metadata
              }
            }
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
                                                    variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']

    assert_not_empty data, 'samples type should work'
    assert_not_empty data['nodes']
    assert_equal 1, data['nodes'].count

    assert_not_empty data['nodes'][0]['attachments']
    assert_not_empty data['nodes'][0]['attachments']['edges']

    attachments = data['nodes'][0]['attachments']['edges']
    assert_equal 2, attachments.count

    assert_equal 'test_file.fastq', attachments[0]['node']['filename']
    assert_equal 'test_file_A.fastq', attachments[1]['node']['filename']

    assert_equal 2102, attachments[0]['node']['byteSize']
    assert_equal 2101, attachments[1]['node']['byteSize']

    assert_equal 'fastq', attachments[0]['node']['metadata']['format']
    assert_equal 'none', attachments[0]['node']['metadata']['compression']
    assert_equal 'fastq', attachments[1]['node']['metadata']['format']
    assert_equal 'none', attachments[1]['node']['metadata']['compression']
  end

  test 'attachment url query should work' do
    result = IridaSchema.execute(ATTACHMENTS_URL_QUERY, context: { current_user: @user },
                                                        variables: { first: 1 })

    # get blob storage file urls
    file1 = @sample.attachments[0].file
    file2 = @sample.attachments[1].file
    file_url1 = Rails.application.routes.url_helpers.rails_blob_url(file1)
    file_url2 = Rails.application.routes.url_helpers.rails_blob_url(file2)

    assert_nil result['errors'], 'should work and have no errors.'

    attachments = result['data']['samples']['nodes'][0]['attachments']['edges']
    assert_equal 2, attachments.count

    assert_equal file_url1, attachments[0]['node']['attachmentUrl']
    assert_equal file_url2, attachments[1]['node']['attachmentUrl']
  end

  test 'attachment metadata delimit query should work' do
    result = IridaSchema.execute(ATTACHMENTS_METADATA_QUERY, context: { current_user: @user },
                                                             variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    attachments = result['data']['samples']['nodes'][0]['attachments']['edges']
    metadata1 = attachments[0]['node']['metadata']
    metadata2 = attachments[1]['node']['metadata']

    assert_equal 'fastq', metadata1['format'], "should have requested 'format'"
    assert_equal 'fastq', metadata2['format'], "should have requested 'format'"

    assert_nil metadata1['compression'], 'should not have field that was not requested'
    assert_nil metadata2['compression'], 'should not have field that was not requested'
  end

  test 'attachment paired query should work' do
    result = IridaSchema.execute(
      ATTACHMENTS_PAIRED_QUERY,
      context: { current_user: @user_paired },
      variables: { first: 2, samp_id: @sample_paired.to_global_id.to_s }
    )

    assert_nil result['errors'], 'should work and have no errors.'

    attachment1 = result['data']['node']['attachments']['edges'][0]
    attachment2 = result['data']['node']['attachments']['edges'][1]
    metadata1 = attachment1['node']['metadata']
    metadata2 = attachment2['node']['metadata']

    assert_equal 'forward', metadata1['direction']
    assert_equal 'reverse', metadata2['direction']

    assert_equal 'pe', metadata1['type']
    assert_equal 'pe', metadata2['type']

    # check they reference each other
    assert_equal attachment1['node']['id'], "gid://irida/Attachment/#{metadata2['associated_attachment_id']}"
    assert_equal attachment2['node']['id'], "gid://irida/Attachment/#{metadata1['associated_attachment_id']}"
  end
end
