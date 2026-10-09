# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class ImportSamplesTest < ActionDispatch::IntegrationTest
      FIXTURE_DIR = Rails.root.join('test/fixtures/files/batch_sample_import/project')

      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
        @project = projects(:project1)
        @namespace = groups(:group_one)
        @broadcast_target = "samples_import_test_#{SecureRandom.uuid}"
      end

      test 'should import samples' do
        ### SETUP START ###
        assert_samples_table(count: 3)
        ### SETUP END ###

        ### ACTIONS START ###
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post_spreadsheet_import('valid.csv', sample_description_column: 'description')
        end
        assert_response :success
        ### ACTIONS END ###

        ### VERIFY START ###
        broadcasts = perform_import_job
        success_broadcast = find_import_broadcast(broadcasts)
        assert_not_nil success_broadcast
        assert_includes success_broadcast.to_html, I18n.t('shared.samples.spreadsheet_imports.success.description')

        # added 2 new samples
        assert_samples_table(count: 5)
        assert_select 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_select 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        ### VERIFY END ###
      end

      test 'should import partial data when some rows are invalid' do
        # Using short sample name to test this.
        ### SETUP START ###
        assert_samples_table(count: 3)
        assert_select 'table tbody tr td:nth-child(2)', text: 'my new sample', count: 0
        ### SETUP END ###

        ### ACTIONS START ###
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post_spreadsheet_import('invalid_short_sample_name.csv', sample_description_column: 'description')
        end
        assert_response :success
        ### ACTIONS END ###

        ### VERIFY START ###
        broadcasts = perform_import_job
        success_broadcast = find_import_broadcast(broadcasts)
        assert_not_nil success_broadcast
        html = success_broadcast.to_html
        assert_includes html, I18n.t('shared.samples.spreadsheet_imports.success.description')
        # problem message
        assert_includes html, I18n.t('shared.samples.spreadsheet_imports.success.problems')

        # problem table has 1 problem
        broadcast_fragment = Nokogiri::HTML::DocumentFragment.parse(html)
        assert_select broadcast_fragment, '#problems_table tbody tr', count: 1
        assert_select broadcast_fragment, '#problems_table tbody tr',
                      text: /m sample name is too short \(minimum is 3 characters\)/

        # added 1 new sample
        assert_samples_table(count: 4)
        assert_select 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample'
        ### VERIFY END ###
      end

      test 'should not import samples when file malformed' do
        # Using duplicate file header to test this.
        ### SETUP START ###
        assert_samples_table(count: 3)
        ### SETUP END ###

        ### ACTIONS START ###
        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post_spreadsheet_import('invalid_duplicate_header.csv', sample_description_column: 'description')
        end
        assert_response :success
        ### ACTIONS END ###

        ### VERIFY START ###
        broadcasts = perform_import_job
        error_broadcast = find_import_broadcast(broadcasts)
        assert_not_nil error_broadcast
        assert_includes error_broadcast.to_html, I18n.t('shared.samples.spreadsheet_imports.errors.description')
        assert_includes error_broadcast.to_html, I18n.t('services.spreadsheet_import.duplicate_column_names')

        # added 0 new samples
        assert_samples_table(count: 3)
        assert_select 'table tbody tr td:nth-child(2)', text: 'my new sample', count: 0
        ### VERIFY END ###
      end

      test 'should enqueue a Samples::BatchSampleImportJob' do
        blob_file = active_storage_blobs(:project_sample_import_valid_csv_blob)

        assert_enqueued_jobs 1, only: ::Samples::BatchSampleImportJob do
          post namespace_project_samples_spreadsheet_import_path(@namespace, @project, format: :turbo_stream),
               params: {
                 spreadsheet_import: {
                   file: blob_file.signed_id,
                   sample_id_column: 'sample_name'
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end

      private

      def assert_samples_table(count:)
        get namespace_project_samples_path(@namespace, @project)

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
                                  metadata_fields: [])
        blob = create_spreadsheet_import_blob(filename)

        post namespace_project_samples_spreadsheet_import_path(@namespace, @project, format: :turbo_stream),
             params: {
               spreadsheet_import: {
                 file: blob.signed_id,
                 sample_name_column: sample_name_column,
                 sample_description_column: sample_description_column,
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
