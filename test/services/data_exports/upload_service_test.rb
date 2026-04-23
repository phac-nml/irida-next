# frozen_string_literal: true

require 'test_helper'

module DataExports
  class UploadServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample1 = samples(:sample1)
      @project1 = projects(:project1)
    end

    test 'rolls back persisted data export when file attachment fails' do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/data_export_8.csv'),
        'text/csv'
      )
      params = upload_params(file:, linelist_format: 'csv')
      service = DataExports::UploadService.new(@user, params)
      service.stubs(:attach_file).raises(
        DataExports::UploadService::DataExportUploadError.new(
          I18n.t('services.data_exports.upload.attach_failed')
        )
      )

      assert_no_difference -> { DataExport.count } do
        data_export = service.execute
        assert_includes data_export.errors.full_messages,
                        I18n.t('services.data_exports.upload.attach_failed')
      end
    end

    test 'rejects spoofed content type when detected MIME type does not match format' do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/attachment_preview.webp'),
        'text/csv'
      )
      params = upload_params(file:, linelist_format: 'csv')

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::UploadService.new(@user, params).execute
        assert_includes data_export.errors.full_messages.to_sentence,
                        I18n.t('services.data_exports.upload.invalid_file_type', file_format: 'CSV')
      end
    end

    private

    def upload_params(file:, linelist_format:)
      {
        'name' => 'upload service test',
        'file' => file,
        'export_parameters' => {
          'ids' => [@sample1.id],
          'namespace_id' => @project1.namespace.id,
          'linelist_format' => linelist_format,
          'metadata_fields' => ['metadatafield1']
        }
      }
    end
  end
end
