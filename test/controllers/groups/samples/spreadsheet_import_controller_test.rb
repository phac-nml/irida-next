# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class SpreadsheetImportControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @group = groups(:group_one)
        @blob_file = active_storage_blobs(:group_sample_import_valid_csv_blob)
        Flipper.enable(:batch_sample_spreadsheet_import)
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post group_samples_spreadsheet_import_path(@group, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: @blob_file.signed_id,
                   sample_id_column: 'sample_name',
                   project_puid_column: 'project_puid'
                 }
               }
        end
      end
    end
  end
end
