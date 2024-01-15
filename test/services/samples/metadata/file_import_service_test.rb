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

        @csv = File.open('test/fixtures/files/metadata/valid.csv', 'r')
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
      end

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
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.empty_sample_id_column'))
      end

      test 'import sample metadata with no file' do
        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.empty_file'))
      end

      test 'import sample metadata via csv file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        params = { file: @csv, sample_id_column: 'sample_name' }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xls file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        xls = File.new('test/fixtures/files/metadata/valid.xls', 'r')
        params = { file: xls, sample_id_column: 'sample_name' }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] } }, response)
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 20, 'metadatafield3' => 30 },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => 15, 'metadatafield2' => 25, 'metadatafield3' => 35 },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xlsx file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        xlsx = File.new('test/fixtures/files/metadata/valid.xlsx', 'r')
        params = { file: xlsx, sample_id_column: 'sample_name' }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] } }, response)
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 20, 'metadatafield3' => 30 },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => 15, 'metadatafield2' => 25, 'metadatafield3' => 35 },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via other file' do
        other = File.new('test/fixtures/files/metadata/invalid.txt', 'r')
        params = { file: other, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.invalid_file_extension'))
      end

      test 'import sample metadata with no sample_id_column' do
        csv = File.new('test/fixtures/files/metadata/missing_sample_id_column.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.missing_sample_id_column'))
      end

      test 'import sample metadata with duplicate column names' do
        csv = File.new('test/fixtures/files/metadata/duplicate_headers.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.duplicate_column_names'))
      end

      test 'import sample metadata with no metadata columns' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_columns.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.missing_metadata_column'))
      end

      test 'import sample metadata with no metadata rows' do
        csv = File.new('test/fixtures/files/metadata/missing_metadata_rows.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal(@project.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.metadata.import_file.missing_metadata_row'))
      end

      test 'import sample metadata with empty values set to true' do
        sample32 = samples(:sample32)
        project29 = projects(:project29)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample32.metadata)
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: true }
        response = Samples::Metadata::FileImportService.new(project29, @john_doe, params).execute
        assert_equal({ sample32.name => { added: ['metadatafield3'], updated: ['metadatafield2'],
                                          deleted: [], not_updated: [] } }, response)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     sample32.reload.metadata)
      end

      test 'import sample metadata with empty values set to false' do
        sample32 = samples(:sample32)
        project29 = projects(:project29)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample32.metadata)
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: false }
        response = Samples::Metadata::FileImportService.new(project29, @john_doe, params).execute
        assert_equal({ sample32.name => { added: ['metadatafield3'], updated: ['metadatafield2'],
                                          deleted: ['metadatafield1'], not_updated: [] } }, response)
        assert_equal({ 'metadatafield2' => '20', 'metadatafield3' => '30' }, sample32.reload.metadata)
      end

      test 'import sample metadata with a sample that does not belong to project' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        csv = File.new('test/fixtures/files/metadata/mixed_project_samples.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [] } }, response)
        assert_equal("Sample 'Project 2 Sample 1' is not found within this project",
                     @project.errors.full_messages_for(:sample).first)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({}, @sample2.reload.metadata)
      end

      test 'import sample metadata with empty values set to true' do
        @sample1.metadata = { 'metadatafield1' => '1', 'metadatafield2' => '2', 'metadatafield3' => '3' }
        @sample1.save
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: true }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
        assert_equal(
          { @sample1.name => { updated: %w[metadatafield2 metadatafield3], not_updated: [] },
            @sample2.name => { updated: %w[metadatafield1 metadatafield3], not_updated: [] } }, response
        )
        assert_equal({ 'metadatafield1' => '1', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end

      test 'import sample metadata with empty values set to false' do
        @sample1.metadata = { 'metadatafield1' => '1', 'metadatafield2' => '2', 'metadatafield3' => '3' }
        @sample1.save
        csv = File.new('test/fixtures/files/metadata/contains_empty_values.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name', ignore_empty_values: false }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
        assert_equal(
          { @sample1.name => { updated: %w[metadatafield1 metadatafield2 metadatafield3], not_updated: [] },
            @sample2.name => { updated: %w[metadatafield1 metadatafield3], not_updated: [] } }, response
        )
        assert_equal({ 'metadatafield2' => '20', 'metadatafield3' => '30' }, @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end

      test 'import sample metadata with a sample that does not belong to project' do
        csv = File.new('test/fixtures/files/metadata/mixed_project_samples.csv', 'r')
        params = { file: csv, sample_id_column: 'sample_name' }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute
        assert_equal({ @sample1.name => { updated: %w[metadatafield1 metadatafield2 metadatafield3], not_updated: [] } },
                     response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({}, @sample2.reload.metadata)
      end
    end
  end
end
