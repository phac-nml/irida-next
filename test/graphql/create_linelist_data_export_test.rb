# frozen_string_literal: true

require 'test_helper'

class CreateLinelistDataExportTest < ActiveSupport::TestCase
  CREATE_LINELIST_DATA_EXPORT_MUTATION = <<~GRAPHQL
    mutation(
      $name: String
      $signedBlobId: ID!
      $namespaceId: ID!
      $linelistFormat: String!
      $sampleIds: [ID!]!
      $metadataFields: [String!]
    ) {
      createLinelistDataExport(input: {
        name: $name
        signedBlobId: $signedBlobId
        namespaceId: $namespaceId
        linelistFormat: $linelistFormat
        sampleIds: $sampleIds
        metadataFields: $metadataFields
      }) {
        id
        url
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
    @sample1 = samples(:sample1)
    @project1 = projects(:project1)
  end

  test 'createLinelistDataExport creates ready export with valid direct-uploaded csv blob' do
    blob = upload_blob(
      io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
      filename: 'linelist.csv',
      content_type: 'text/csv'
    )

    assert_difference -> { DataExport.count }, 1 do
      result = execute_mutation(blob:)

      assert_nil result['errors']
      data = result['data']['createLinelistDataExport']
      assert_empty data['errors']
      assert_equal Rails.application.routes.url_helpers.data_export_path(DataExport.find(data['id'])), data['url']
    end

    data_export = DataExport.last
    assert_equal 'ready', data_export.status
    assert_equal 'linelist', data_export.export_type
    assert_equal 'saved linelist', data_export.name
    assert data_export.file.attached?
    assert_equal "#{data_export.id}.csv", data_export.file.filename.to_s
  end

  test 'createLinelistDataExport rejects invalid signed blob id' do
    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob: nil, signed_blob_id: 'invalid')

      data = result['data']['createLinelistDataExport']
      assert_nil data['id']
      assert_nil data['url']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('services.data_exports.linelist_create.invalid_signed_blob_id')
    end
  end

  test 'createLinelistDataExport rejects invalid content type' do
    blob = upload_blob(
      io: Rails.root.join('test/fixtures/files/attachment_preview.webp').open,
      filename: 'linelist.csv',
      content_type: 'image/webp'
    )

    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob:)

      data = result['data']['createLinelistDataExport']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('services.data_exports.upload.invalid_file_type', file_format: 'CSV')
    end
  end

  test 'createLinelistDataExport rejects oversized blob' do
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: 'too-large.csv',
      byte_size: DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES + 1,
      checksum: Base64.strict_encode64(Digest::MD5.digest('')),
      content_type: 'text/csv'
    )

    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob:)

      data = result['data']['createLinelistDataExport']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('services.data_exports.upload.file_too_large',
                             max_mb: DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES / 1.megabyte)
    end
  end

  test 'createLinelistDataExport rejects bad namespace' do
    blob = upload_blob(
      io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
      filename: 'linelist.csv',
      content_type: 'text/csv'
    )

    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob:, namespace_id: SecureRandom.uuid)

      data = result['data']['createLinelistDataExport']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id')
    end
  end

  test 'createLinelistDataExport rejects samples outside namespace authorization scope' do
    blob = upload_blob(
      io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
      filename: 'linelist.csv',
      content_type: 'text/csv'
    )

    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob:, sample_ids: [samples(:sample23).id])

      data = result['data']['createLinelistDataExport']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('services.data_exports.create.invalid_export_samples')
    end
  end

  test 'createLinelistDataExport rejects invalid format' do
    blob = upload_blob(
      io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
      filename: 'linelist.tsv',
      content_type: 'text/csv'
    )

    assert_no_difference -> { DataExport.count } do
      result = execute_mutation(blob:, linelist_format: 'tsv')

      data = result['data']['createLinelistDataExport']
      assert_includes data['errors'].pluck('message'),
                      I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format')
    end
  end

  private

  def execute_mutation(blob:, signed_blob_id: nil, namespace_id: @project1.namespace.id,
                       linelist_format: 'csv', sample_ids: [@sample1.id])
    IridaSchema.execute(
      CREATE_LINELIST_DATA_EXPORT_MUTATION,
      context: { current_user: @user, token: @api_scope_token },
      variables: {
        name: 'saved linelist',
        signedBlobId: signed_blob_id || blob.signed_id,
        namespaceId: namespace_id,
        linelistFormat: linelist_format,
        sampleIds: sample_ids,
        metadataFields: ['metadatafield1']
      }
    )
  end

  def upload_blob(io:, filename:, content_type:)
    ActiveStorage::Blob.create_and_upload!(
      io:,
      filename:,
      content_type:
    )
  end
end
