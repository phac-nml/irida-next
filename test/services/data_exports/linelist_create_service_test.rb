# frozen_string_literal: true

require 'test_helper'

module DataExports
  class LinelistCreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample1 = samples(:sample1)
      @project1 = projects(:project1)
    end

    test 'creates ready linelist csv export from direct-uploaded blob' do
      blob = upload_blob(
        io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
        filename: 'linelist.csv',
        content_type: 'text/csv'
      )

      assert_difference -> { DataExport.count }, 1 do
        data_export = DataExports::LinelistCreateService.new(@user, params(blob)).execute

        assert data_export.persisted?
        assert_equal 'ready', data_export.status
        assert_equal 'linelist', data_export.export_type
        assert_equal 'saved linelist', data_export.name
        assert_equal [@sample1.id], data_export.export_parameters['ids']
        assert_equal ['metadatafield1'], data_export.export_parameters['metadata_fields']
        assert_equal @project1.namespace.id, data_export.export_parameters['namespace_id']
        assert_equal ApplicationController.helpers.add_business_days(Date.current, 3).to_date,
                     data_export.expires_at.to_date
        assert data_export.file.attached?
        assert_equal "#{data_export.id}.csv", data_export.file.filename.to_s
      end
    end

    test 'rejects invalid signed blob id' do
      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::LinelistCreateService.new(
          @user,
          params(nil).merge('signed_blob_id' => 'invalid')
        ).execute

        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t('services.data_exports.linelist_create.invalid_signed_blob_id')
      end
    end

    test 'rejects invalid content type' do
      blob = upload_blob(
        io: Rails.root.join('test/fixtures/files/attachment_preview.webp').open,
        filename: 'linelist.csv',
        content_type: 'image/webp'
      )

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::LinelistCreateService.new(@user, params(blob)).execute

        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t('services.data_exports.upload.invalid_file_type', file_format: 'CSV')
      end
    end

    test 'rejects oversized blob before attachment' do
      blob = ActiveStorage::Blob.create_before_direct_upload!(
        filename: 'too-large.csv',
        byte_size: DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES + 1,
        checksum: Base64.strict_encode64(Digest::MD5.digest('')),
        content_type: 'text/csv'
      )

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::LinelistCreateService.new(@user, params(blob)).execute

        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t('services.data_exports.upload.file_too_large',
                               max_mb: DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES / 1.megabyte)
      end
    end

    test 'rejects invalid format' do
      blob = upload_blob(
        io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
        filename: 'linelist.tsv',
        content_type: 'text/csv'
      )

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::LinelistCreateService.new(
          @user,
          params(blob).merge('linelist_format' => 'tsv')
        ).execute

        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t(
                          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'
                        )
      end
    end

    test 'rejects samples outside authorized namespace scope' do
      blob = upload_blob(
        io: StringIO.new("SAMPLE PUID\n#{@sample1.puid}\n"),
        filename: 'linelist.csv',
        content_type: 'text/csv'
      )

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::LinelistCreateService.new(
          @user,
          params(blob).merge('sample_ids' => [samples(:sample23).id])
        ).execute

        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t('services.data_exports.create.invalid_export_samples')
      end
    end

    private

    def params(blob)
      {
        'name' => 'saved linelist',
        'signed_blob_id' => blob&.signed_id,
        'namespace_id' => @project1.namespace.id,
        'linelist_format' => 'csv',
        'sample_ids' => [@sample1.id],
        'metadata_fields' => ['metadatafield1']
      }
    end

    def upload_blob(io:, filename:, content_type:)
      ActiveStorage::Blob.create_and_upload!(
        io:,
        filename:,
        content_type:
      )
    end
  end
end
