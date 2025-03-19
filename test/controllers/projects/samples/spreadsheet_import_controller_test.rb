# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class SpreadsheetImportControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @csv = fixture_file_upload('test/fixtures/files/batch_sample_import/project/valid.csv')

        Flipper.enable(:batch_sample_spreadsheet_import)
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post namespace_project_samples_spreadsheet_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: @csv,
                   sample_id_column: 'sample_name'
                 }
               }
        end
      end
    end
  end
end
