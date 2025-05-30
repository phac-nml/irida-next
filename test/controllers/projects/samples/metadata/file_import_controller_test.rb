# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Metadata
      class FileImportControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_in users(:john_doe)
          @namespace = groups(:group_one)
          @project = projects(:project1)
          @blob_file = active_storage_blobs(:metadata_valid_csv_blob)
        end

        test 'should enqueue a Samples::MetadataImportJob' do
          assert_enqueued_jobs 1, only: ::Samples::MetadataImportJob do
            post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
                 params: {
                   file_import: {
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
end
