# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @project = projects(:project1)

        @csv = File.new('test/fixtures/files/metadata/valid.csv', 'r')
      end

      # bin/rails test test/services/samples/metadata/file_import_service_test.rb

      test 'import sample metadata with permission' do
        assert_authorized_to(:update_sample?, @project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          params = { file: @csv, sample_id_column: 'sample_id', ignore_empty_values: true }
          Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        end
      end

      test 'import sample metadata without permission' do
        assert_raises(ActionPolicy::Unauthorized) do
          params = { file: @csv, sample_id_column: 'sample_id', ignore_empty_values: true }
          Samples::Metadata::FileImportService.new(@project, @jane_doe, params).execute
        end
      end

      test 'import sample metadata with empty params' do
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe, {}).execute
      end

      test 'import sample metadata via csv file' do
        params = { file: @csv, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
      end

      test 'import sample metadata via xls file' do
        xls = File.new('test/fixtures/files/metadata/valid.xls', 'r')
        params = { file: xls, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
      end

      test 'import sample metadata via xlsx file' do
        xlsx = File.new('test/fixtures/files/metadata/valid.xlsx', 'r')
        params = { file: xlsx, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
      end

      test 'import sample metadata via other file' do
        other = File.new('test/fixtures/files/metadata/invalid.txt', 'r')
        params = { file: other, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
      end

      test 'import sample metadata with no sample_id_column' do
        csv = File.new('test/fixtures/files/metadata/missing_sample_id_column.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
      end

      test 'import sample metadata with no metadata columns' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_columns.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
      end

      test 'import sample metadata with no metadata rows' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_rows.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_id', ignore_empty_values: true }
        assert_not Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
      end
    end
  end
end
