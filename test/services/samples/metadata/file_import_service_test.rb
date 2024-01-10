# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @project = projects(:project1)

        @csv = File.open('test/fixtures/files/metadata/valid.csv', 'r')
        @excel = File.open('test/fixtures/files/metadata/valid.xlsx', 'r')
        @other = File.open('test/fixtures/files/metadata/invalid.txt', 'r')
      end

      # bin/rails test test/services/samples/metadata/file_import_service_test.rb

      test 'import sample metadata with empty params' do
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe, {}).execute
      end

      test 'import sample metadata with permission' do
        assert_authorized_to(:update_sample?, @project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          params = { file: @csv, sample_id_column: 'sample_name', ignore_empty_values: true }
          Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        end
      end

      test 'import sample metadata without permission' do
        assert_raises(ActionPolicy::Unauthorized) do
          params = { file: @csv, sample_id_column: 'sample_name', ignore_empty_values: true }
          Samples::Metadata::FileImportService.new(@project, @jane_doe, params).execute
        end
      end

      test 'import sample metadata via csv file' do
        params = { file: @csv, sample_id_column: 'sample_name', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
      end

      test 'import sample metadata via excel file' do
        params = { file: @excel, sample_id_column: 'sample_name', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
      end

      test 'import sample metadata via other file' do
        params = { file: @other, sample_id_column: 'sample_name', ignore_empty_values: true }
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
      end
    end
  end
end
