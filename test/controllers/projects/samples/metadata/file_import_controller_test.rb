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
          @sample = samples(:sample1)
        end

        test 'should create sample metadata file import' do
          post namespace_project_sample_metadata_import_file_path(@namespace, @project, @sample)

          assert_response :success
        end
      end
    end
  end
end
