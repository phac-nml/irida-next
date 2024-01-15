# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @project = projects(:project1)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)

        @csv = File.new('test/fixtures/files/metadata/valid.csv', 'r')
      end

      # bin/rails test test/services/samples/metadata/file_import_service_test.rb

      test 'import sample metadata with permission' do
        assert_authorized_to(:update_sample?, @project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          params = { file: @csv, sample_id_column: 'sample_name' }
          Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        end
      end

      test 'import sample metadata without permission' do
        assert_raises(ActionPolicy::Unauthorized) do
          params = { file: @csv, sample_id_column: 'sample_name' }
          Samples::Metadata::FileImportService.new(@project, @jane_doe, params).execute
        end
      end

      test 'import sample metadata with empty params' do
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, {}).execute
      end

      test 'import sample metadata via csv file' do
        params = { file: @csv, sample_id_column: 'sample_name' }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xls file' do
        xls = File.new('test/fixtures/files/metadata/valid.xls', 'r')
        params = { file: xls, sample_id_column: 'sample_name' }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 20, 'metadatafield3' => 30 },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => 15, 'metadatafield2' => 25, 'metadatafield3' => 35 },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xlsx file' do
        xlsx = File.new('test/fixtures/files/metadata/valid.xlsx', 'r')
        params = { file: xlsx, sample_id_column: 'sample_name' }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 20, 'metadatafield3' => 30 },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => 15, 'metadatafield2' => 25, 'metadatafield3' => 35 },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via other file' do
        other = File.new('test/fixtures/files/metadata/invalid.txt', 'r')
        params = { file: other, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                              params).execute
      end

      test 'import sample metadata with no sample_id_column' do
        csv = File.new('test/fixtures/files/metadata/missing_sample_id_column.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                              params).execute
      end

      test 'import sample metadata with no metadata columns' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_columns.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                              params).execute
      end

      test 'import sample metadata with no metadata rows' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_rows.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                              params).execute
      end

      test 'import sample metadata with empty values set to true' do
        @sample1.metadata = { 'metadatafield1' => '1', 'metadatafield2' => '2', 'metadatafield3' => '3' }
        @sample1.save
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: true }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
        assert_equal({ 'metadatafield1' => '1', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end

      test 'import sample metadata with empty values set to false' do
        @sample1.metadata = { 'metadatafield1' => '1', 'metadatafield2' => '2', 'metadatafield3' => '3' }
        @sample1.save
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: false }
        assert Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                        params).execute
        assert_equal({ 'metadatafield2' => '20', 'metadatafield3' => '30' }, @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end
    end
  end
end
