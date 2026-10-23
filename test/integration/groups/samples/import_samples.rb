# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class ImportSamplesTest < ActionDispatch::IntegrationTest
      FIXTURE_DIR = Rails.root.join('test/fixtures/files/batch_sample_import/group')

      setup do
        @user = users(:john_doe)
        sign_in @user
        @group = groups(:group_one)
        @broadcast_target = "group_samples_import_test_#{SecureRandom.uuid}"
      end

      test 'should import samples' do
        ### SETUP START ###
        assert_samples_table(count: 26)
        ### SETUP END ###

        ### ACTIONS START ###
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post_spreadsheet_import('valid.csv', sample_description_column: 'description',
                                               project_puid_column: 'project_puid')
        end
        assert_response :success
        ### ACTIONS END ###

        ### VERIFY START ###
        broadcasts = perform_import_job
        success_broadcast = find_import_broadcast(broadcasts)
        assert_not_nil success_broadcast
        assert_includes success_broadcast.to_html, I18n.t('shared.samples.spreadsheet_imports.success.description')

        assert_samples_table(count: 28)
        assert_select 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_select 'table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
        assert_select 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        assert_select 'table tbody tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
        ### VERIFY END ###
      end

      test 'should not import sample with missing project puid if static project is not selected' do
        ### SETUP START ###
        assert_samples_table(count: 26)
        ### SETUP END ###

        ### ACTIONS START ###
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post_spreadsheet_import('missing_puid.csv', sample_description_column: 'description',
                                                      project_puid_column: 'project_puid')
        end
        assert_response :success
        ### ACTIONS END ###

        ### VERIFY START ###
        broadcasts = perform_import_job
        success_broadcast = find_import_broadcast(broadcasts)
        assert_not_nil success_broadcast
        assert_includes success_broadcast.to_html, I18n.t('shared.samples.spreadsheet_imports.success.description')

        assert_samples_table(count: 27)
        assert_select 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 1'
        assert_select 'table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
        assert_select 'table tbody tr td:nth-child(2)', text: 'my new sample 2', count: 0
        ### VERIFY END ###
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        blob_file = active_storage_blobs(:group_sample_import_valid_csv_blob)
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post group_samples_spreadsheet_import_path(@group, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: blob_file.signed_id,
                   sample_id_column: 'sample_name',
                   project_puid_column: 'project_puid'
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end

      private

      def assert_samples_table(count:)
        get group_samples_path(@group)

        assert_response :success
        assert_select 'table tbody tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def create_spreadsheet_import_blob(filename)
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(FIXTURE_DIR.join(filename)),
          filename: filename,
          content_type: 'text/csv'
        )
      end

      def post_spreadsheet_import(filename, sample_name_column: 'sample_name', sample_description_column: nil,
                                  project_puid_column: nil, metadata_fields: [])
        blob = create_spreadsheet_import_blob(filename)

        post group_samples_spreadsheet_import_path(@group, format: :turbo_stream),
             params: {
               spreadsheet_import: {
                 file: blob.signed_id,
                 sample_name_column: sample_name_column,
                 sample_description_column: sample_description_column,
                 project_puid_column: project_puid_column,
                 metadata_fields: metadata_fields
               }.compact,
               broadcast_target: @broadcast_target
             }
      end

      def perform_import_job
        capture_turbo_stream_broadcasts(@broadcast_target) do
          perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
        end
      end

      def find_import_broadcast(broadcasts)
        broadcasts.find do |message|
          message['action'] == 'replace' && message['target'] == 'import_spreadsheet_dialog_content'
        end
      end
    end
  end
end
