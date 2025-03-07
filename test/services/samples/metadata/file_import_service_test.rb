# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        Flipper.enable(:metadata_import_field_selection)

        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @group = groups(:group_one)
        @project = projects(:project1)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid.csv'))
        @blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )
      end

      test 'import sample metadata with permission for project namespace' do
        assert_authorized_to(:update_sample_metadata?, @project.namespace,
                             with: Namespaces::ProjectNamespacePolicy,
                             context: { user: @john_doe }) do
          params = { sample_id_column: 'sample_name' }
          Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, @blob.id, params).execute
        end
      end

      test 'import sample metadata with permission for group' do
        assert_authorized_to(:update_sample_metadata?, @group,
                             with: GroupPolicy,
                             context: { user: @john_doe }) do
          params = { sample_id_column: 'sample_puid' }
          Samples::Metadata::FileImportService.new(@group, @john_doe, @blob.id, params).execute
        end
      end

      test 'import sample metadata without permission for project namespace' do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          params = { sample_id_column: 'sample_name' }
          Samples::Metadata::FileImportService.new(@project.namespace, @jane_doe, @blob.id, params).execute
        end
        assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_sample_metadata?',
                            name: @project.name), exception.result.message
      end

      test 'import sample metadata without permission for group' do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          params = { sample_id_column: 'sample_puid' }
          Samples::Metadata::FileImportService.new(@group, @jane_doe, @blob.id, params).execute
        end
        assert_equal GroupPolicy, exception.policy
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.update_sample_metadata?',
                            name: @group.name), exception.result.message
      end

      test 'import sample metadata with empty file' do
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/empty.csv'))
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.missing_header', header_title: 'sample_name'))
      end

      test 'import sample metadata via csv file using sample names for project namespace' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, @blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via csv file using sample puids for project namespace' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_puid', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.puid => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.puid => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via csv file using sample names for group' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@group, @john_doe, @blob.id,
                                                              params).execute
        assert_equal(@group.errors.messages_for(:sample).first,
                     I18n.t(
                       'services.samples.metadata.import_file.sample_not_found_within_group',
                       sample_puid: @sample1.name
                     ))
      end

      test 'import sample metadata via csv file using sample puids for group' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_puid',
                   metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@group, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.puid => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.puid => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xls file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid.xls'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name',
                   metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '2024-01-04', 'metadatafield3' => 'true',
                       'metadatafield4' => 'A Test' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '2024-12-31', 'metadatafield3' => 'false',
                       'metadatafield4' => 'Another Test' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via xlsx file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid.xlsx'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name',
                   metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '2024-01-04', 'metadatafield3' => 'true',
                       'metadatafield4' => 'A Test' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '2024-12-31', 'metadatafield3' => 'false',
                       'metadatafield4' => 'Another Test' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via tsv file' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid.tsv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )
        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata via other file' do
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/invalid.txt'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.invalid_file_extension'))
      end

      test 'import sample metadata with no sample_id_column' do
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('test/fixtures/files/metadata/missing_sample_id_column.csv')
        )

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.missing_header', header_title: 'sample_name'))
      end

      test 'import sample metadata with duplicate column names' do
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.duplicate_column_names'))
      end

      test 'import sample metadata with no metadata columns' do
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        )

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.missing_data_columns'))
      end

      test 'import sample metadata with no metadata rows' do
        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name' }
        assert_empty Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.missing_data_row'))
      end

      test 'import sample metadata with an empty header' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/contains_empty_header.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield3' => '30' }, @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end

      test 'import sample metadata with multiple empty columns' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/contains_empty_columns.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield3' => '30' }, @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield3' => '35' }, @sample2.reload.metadata)
      end

      test 'import sample metadata with empty values set to true' do
        sample32 = samples(:sample32)
        project29 = projects(:project29)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample32.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3],
                   ignore_empty_values: true }
        response = Samples::Metadata::FileImportService.new(project29.namespace, @john_doe, blob.id, params).execute
        assert_equal({ sample32.name => { added: ['metadatafield3'], updated: ['metadatafield2'],
                                          deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     sample32.reload.metadata)
      end

      test 'import sample metadata with user unable to overwrite analysis' do
        sample34 = samples(:sample34)
        project31 = projects(:project31)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample34.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => '2000-01-01T00:00:00.000+00:00' } },
                     sample34.metadata_provenance)
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
        )

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(project31.namespace, @john_doe, blob.id, params).execute
        assert_empty response
        assert_equal("Sample 'Sample 34' with field(s) 'metadatafield1' cannot be updated.",
                     project31.namespace.errors.messages_for(:sample).first)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => '20' },
                     sample34.reload.metadata)
      end

      test 'import sample metadata with empty values set to false' do
        sample32 = samples(:sample32)
        project29 = projects(:project29)
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, sample32.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3],
                   ignore_empty_values: false }
        response = Samples::Metadata::FileImportService.new(project29.namespace, @john_doe, blob.id, params).execute
        assert_equal({ sample32.name => { added: ['metadatafield3'], updated: ['metadatafield2'],
                                          deleted: ['metadatafield1'], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield2' => '20', 'metadatafield3' => '30' }, sample32.reload.metadata)
      end

      test 'import sample metadata with whitespace keys and values' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(
          Rails.root.join('test/fixtures/files/metadata/contains_whitespace_keys_and_values.csv')
        )

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )

        params = { sample_id_column: 'sample_name',
                   metadata_columns: ['sample_name', 'metadatafield1', ' metadatafield2 ', 'metadatafield3'] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                     @sample2.reload.metadata)
      end

      test 'import sample metadata with a sample that does not belong to project' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv'))

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )
        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, blob.id, params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1 metadatafield2 metadatafield3],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)

        assert_equal(I18n.t(
                       'services.samples.metadata.import_file.sample_not_found_within_project',
                       sample_puid: 'Project 2 Sample 3'
                     ),
                     @project.namespace.errors.messages_for(:sample).first)
        assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                     @sample1.reload.metadata)
        assert_equal({}, @sample2.reload.metadata)
      end

      test 'import sample metadata selecting a column' do
        assert_equal({}, @sample1.metadata)
        assert_equal({}, @sample2.metadata)
        params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1] }
        response = Samples::Metadata::FileImportService.new(@project.namespace, @john_doe, @blob.id,
                                                            params).execute
        assert_equal({ @sample1.name => { added: %w[metadatafield1],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] },
                       @sample2.name => { added: %w[metadatafield1],
                                          updated: [], deleted: [], not_updated: [], unchanged: [] } }, response)
        assert_equal({ 'metadatafield1' => '10' },
                     @sample1.reload.metadata)
        assert_equal({ 'metadatafield1' => '15' },
                     @sample2.reload.metadata)
      end
    end
  end
end
