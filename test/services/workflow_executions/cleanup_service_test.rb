# frozen_string_literal: true

require 'active_storage_test_case'

module WorkflowExecutions
  include BlobHelper

  class CleanupServiceTest < ActiveStorageTestCase
    def setup # rubocop:disable Metrics/MethodLength
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
      @workflow_execution.blob_run_directory = generate_run_directory

      output_file = 'test/fixtures/files/blob_outputs/normal/summary.txt'
      @output_file_blob = make_and_upload_blob(
        filepath: output_file,
        blob_run_directory: @workflow_execution.blob_run_directory,
        gzip: false,
        prefix: 'output/'
      )
      input_file = 'test/fixtures/files/samp_F.fastq'
      @input_file_blob = make_and_upload_blob(
        filepath: input_file,
        blob_run_directory: @workflow_execution.blob_run_directory,
        gzip: false,
        prefix: 'input/'
      )
      samplesheet_file = 'test/fixtures/files/samplesheet.csv'
      @samplesheet_file_blob = make_and_upload_blob(
        filepath: samplesheet_file,
        blob_run_directory: @workflow_execution.blob_run_directory,
        gzip: false,
        prefix: ''
      )
    end

    test 'clean all workflow execution run directory files' do
      # assert_not @workflow_execution.cleaned?

      key = @workflow_execution.blob_run_directory

      assert_equal generate_input_key(run_dir: key, filename: 'samp_F.fastq', prefix: 'input/'), @input_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'summary.txt', prefix: 'output/'), @output_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'samplesheet.csv', prefix: ''), @samplesheet_file_blob.key

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
      end

      @workflow_execution = WorkflowExecutions::CleanupService.new(@workflow_execution, @user, {}).execute

      assert_raises(ActiveStorage::FileNotFoundError) { @output_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @input_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @samplesheet_file_blob.download }

      # assert @workflow_execution.cleaned?
    end
  end
end
