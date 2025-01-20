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
          @csv = fixture_file_upload('test/fixtures/files/metadata/valid.csv')
        end

        test 'import sample metadata with permission' do
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: {
                   file: @csv,
                   sample_id_column: 'sample_name'
                 }
               }

          assert_response :success
        end

        test 'import sample metadata without permission' do
          login_as users(:micha_doe)

          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: {
                   file: @csv,
                   sample_id_column: 'sample_name'
                 }
               }

          assert_response :success
        end

        # test 'import sample metadata with no file' do
        #   post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
        #        params: {
        #          file_import: { sample_id_column: 'sample_name' }
        #        }
        #   assert_response :unprocessable_entity
        # end

        test 'import sample metadata with no sample_id_column' do
          csv = fixture_file_upload('test/fixtures/files/metadata/missing_sample_id_column.csv')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: { file: csv, sample_id_column: 'sample_name' }
               }
          assert_response :success
        end

        test 'import sample metadata with duplicate column names' do
          csv = fixture_file_upload('test/fixtures/files/metadata/duplicate_headers.csv')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: { file: csv, sample_id_column: 'sample_name' }
               }
          assert_response :success
        end

        test 'import sample metadata with no metadata columns' do
          csv = fixture_file_upload('test/fixtures/files/metadata/missing_metadata_columns.csv')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: { file: csv, sample_id_column: 'sample_name' }
               }
          assert_response :success
        end

        test 'import sample metadata with no metadata rows' do
          csv = fixture_file_upload('test/fixtures/files/metadata/missing_metadata_rows.csv')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: { file: csv, sample_id_column: 'sample_name' }
               }
          assert_response :success
        end

        test 'import sample metadata with invalid file' do
          other = fixture_file_upload('test/fixtures/files/metadata/invalid.txt')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: {
                   file: other,
                   sample_id_column: 'sample_name'
                 }
               }

          assert_response :success
        end

        test 'import sample metadata with a sample that does not belong to project' do
          csv = fixture_file_upload('test/fixtures/files/metadata/mixed_project_samples.csv')
          post namespace_project_samples_file_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 file_import: {
                   file: csv,
                   sample_id_column: 'sample_name'
                 }
               }

          assert_response :success
        end
      end
    end
  end
end
