# frozen_string_literal: true

require 'active_job/continuation/test_helper'
require 'test_helper'
require 'test_helpers/blob_test_helpers'
require 'test_helpers/faraday_test_helpers'

class WorkflowExecutionCompletionJobTest < ActiveJob::TestCase
  include BlobTestHelpers
  include FaradayTestHelpers
  include ActiveJob::Continuation::TestHelper

  def setup
    @workflow_execution_canceling = workflow_executions(:irida_next_example_canceling)

    # get a new secure token the workflow execution
    @workflow_execution_completing = workflow_executions(:irida_next_example_completing_a)
    blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
    @workflow_execution_completing.blob_run_directory = blob_run_directory_a
    @workflow_execution_completing.save

    # create file blobs
    @normal_output_json_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal/iridanext.output.json',
      blob_run_directory: blob_run_directory_a,
      gzip: true
    )
    @normal_output_summary_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal/summary.txt',
      blob_run_directory: blob_run_directory_a
    )
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'successful job execution' do
    workflow_execution = @workflow_execution_completing

    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob) do
      WorkflowExecutionCompletionJob.perform_later(workflow_execution)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(1, only: WorkflowExecutionCompletionJob)
    workflow_execution.reload.state.to_sym == :completed
  end

  test 'successful invalid execution' do
    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob) do
      WorkflowExecutionCompletionJob.perform_later(@workflow_execution_canceling)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(1, only: WorkflowExecutionCompletionJob)
    @workflow_execution_canceling.reload.state.to_sym == :error
  end

  test 'job resumes from correct step' do
    workflow_execution = @workflow_execution_completing

    WorkflowExecutionCompletionJob.perform_later(workflow_execution)

    assert_equal 'completing', workflow_execution.state
    assert_equal 0, workflow_execution.outputs.count
    interrupt_job_after_step(WorkflowExecutionCompletionJob, :process_global_file_paths) do
      perform_enqueued_jobs(only: WorkflowExecutionCompletionJob)
    end
    workflow_execution.reload

    assert_equal :completing, workflow_execution.state.to_sym
    assert_performed_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_enqueued_jobs(0, only: WorkflowExecutionCleanupJob)

    assert_equal 1, workflow_execution.outputs.count

    interrupt_job_after_step(WorkflowExecutionCompletionJob, :update_state_step) do
      perform_enqueued_jobs(only: WorkflowExecutionCompletionJob)
    end
    workflow_execution.reload

    assert_equal :completed, workflow_execution.state.to_sym
    assert_performed_jobs(2, only: WorkflowExecutionCompletionJob)
    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_enqueued_jobs(0, only: WorkflowExecutionCleanupJob)

    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob)
    workflow_execution.reload

    assert_equal :completed, workflow_execution.state.to_sym
    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(3, only: WorkflowExecutionCompletionJob)
  end
end
