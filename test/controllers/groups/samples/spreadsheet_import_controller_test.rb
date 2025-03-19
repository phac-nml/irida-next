# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class SpreadsheetImportControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @group = groups(:group_one)
        @csv = fixture_file_upload('test/fixtures/files/batch_sample_import/group/valid.csv')

        Flipper.enable(:batch_sample_spreadsheet_import)
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post group_samples_spreadsheet_import_path(@group, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: @csv,
                   sample_id_column: 'sample_name',
                   project_puid_column: 'project_puid'
                 }
               }
        end
      end
    end
  end
end
