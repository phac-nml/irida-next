# frozen_string_literal: true

require 'active_job/continuation/test_helper'
require 'active_storage_test_case'

module WorkflowExecutions
  include BlobHelper

  class CleanupJobTest < ActiveStorageTestCase
    include ActiveJob::Continuation::TestHelper

    def setup # rubocop:disable Metrics/MethodLength
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
      @workflow_execution.blob_run_directory = generate_run_directory
      @workflow_execution.save

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
      unrelated_file = 'test/fixtures/files/md5_a'
      @unrelated_file_blob = make_and_upload_blob(
        filepath: unrelated_file,
        blob_run_directory: nil,
        gzip: false,
        prefix: ''
      )
    end

    test 'clean all workflow execution run directory files' do
      assert_not @workflow_execution.cleaned?

      key = @workflow_execution.blob_run_directory

      assert_equal generate_input_key(run_dir: key, filename: 'samp_F.fastq', prefix: 'input/'), @input_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'summary.txt', prefix: 'output/'), @output_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'samplesheet.csv', prefix: ''), @samplesheet_file_blob.key

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
      end
      @workflow_execution.reload

      assert_raises(ActiveStorage::FileNotFoundError) { @output_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @input_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @samplesheet_file_blob.download }
      assert_nothing_raised { @unrelated_file_blob.download }

      assert @workflow_execution.cleaned?
    end

    test 'clean workflow execution run directory files with interrupt' do
      assert_not @workflow_execution.cleaned?

      key = @workflow_execution.blob_run_directory

      assert_equal generate_input_key(run_dir: key, filename: 'samp_F.fastq', prefix: 'input/'), @input_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'summary.txt', prefix: 'output/'), @output_file_blob.key
      assert_equal generate_input_key(run_dir: key, filename: 'samplesheet.csv', prefix: ''), @samplesheet_file_blob.key

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
      interrupt_job_after_step(WorkflowExecutionCleanupJob, :clean_up_blob_run_directory) do
        perform_enqueued_jobs(only: WorkflowExecutionCleanupJob)
      end
      @workflow_execution.reload

      assert_raises(ActiveStorage::FileNotFoundError) { @output_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @input_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @samplesheet_file_blob.download }
      assert_nothing_raised { @unrelated_file_blob.download }

      assert_not @workflow_execution.cleaned?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob)
      @workflow_execution.reload

      assert_raises(ActiveStorage::FileNotFoundError) { @output_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @input_file_blob.download }
      assert_raises(ActiveStorage::FileNotFoundError) { @samplesheet_file_blob.download }
      assert_nothing_raised { @unrelated_file_blob.download }

      assert @workflow_execution.cleaned?
    end

    test 'do not clean an already cleaned workflow execution' do
      @workflow_execution.cleaned = true
      @workflow_execution.save

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      assert @workflow_execution.completed?
      assert @workflow_execution.cleaned?

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
      end
      @workflow_execution.reload

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      assert @workflow_execution.completed?
      assert @workflow_execution.cleaned?
    end

    test 'do not clean if blob_run_directory is nil' do
      # This tests a safety added to the code, the service should never get a workflow execution in this state
      assert_not @workflow_execution.cleaned?

      @workflow_execution.blob_run_directory = nil
      @workflow_execution.save

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
      end
      @workflow_execution.reload

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      assert @workflow_execution.reload.cleaned?
    end

    test 'do not clean if blob_run_directory is an empty string' do
      # This tests a safety added to the code, the service should never get a workflow execution in this state
      assert_not @workflow_execution.cleaned?

      @workflow_execution.blob_run_directory = ''
      @workflow_execution.save

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
      end
      @workflow_execution.reload

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end

      assert @workflow_execution.reload.cleaned?
    end

    test 'do not clean if workflow execution is nil' do
      # This tests a safety added to the code, the service should never get a workflow execution in this state
      perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
        WorkflowExecutionCleanupJob.perform_later(nil)
      end

      assert_nothing_raised do
        @output_file_blob.download
        @input_file_blob.download
        @samplesheet_file_blob.download
        @unrelated_file_blob.download
      end
    end
  end
end
