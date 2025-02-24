# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class FileImportControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @csv = fixture_file_upload('test/fixtures/files/batch_sample_import_valid.csv')
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post namespace_project_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: {
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
