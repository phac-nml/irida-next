# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class SpreadsheetImportControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @blob_file = active_storage_blobs(:project_sample_import_valid_csv_blob)

        Flipper.enable(:batch_sample_spreadsheet_import)
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post namespace_project_samples_spreadsheet_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: @blob_file.signed_id,
                   sample_id_column: 'sample_name'
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end
    end
  end
end
