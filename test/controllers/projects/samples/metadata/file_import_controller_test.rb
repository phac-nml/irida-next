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
          @sample1 = samples(:sample1)
          @sample2 = samples(:sample2)
          @csv = File.new('test/fixtures/files/metadata/valid.csv', 'r')
        end

        # bin/rails test test/controllers/projects/samples/metadata/file_import_controller_test.rb

        test 'should create sample metadata file import' do
          post namespace_project_samples_file_import_path(@namespace, @project)
          assert_response :success
        end
      end
    end
  end
end
