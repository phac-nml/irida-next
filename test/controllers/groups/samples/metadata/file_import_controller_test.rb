# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    module Metadata
      class FileImportControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_in users(:john_doe)
          @group = groups(:group_one)
          @blob_file = active_storage_blobs(:metadata_valid_csv_blob)
        end

        test 'should enqueue a Samples::MetadataImportJob' do
          assert_enqueued_jobs 1, only: ::Samples::MetadataImportJob do
            post group_samples_file_import_path(@group, format: :turbo_stream),
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
