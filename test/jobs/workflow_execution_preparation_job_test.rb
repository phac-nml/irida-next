# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionPreparationJobTest < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_new)
    @workflow_execution_canceling = workflow_executions(:irida_next_example_canceling)
    @workflow_execution_completed = workflow_executions(:irida_next_example_completed)
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'successful job execution' do
    perform_enqueued_jobs(only: WorkflowExecutionPreparationJob) do
      WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionSubmissionJob)
    assert_performed_jobs(1, only: WorkflowExecutionPreparationJob)
    @workflow_execution.reload.state.to_sym == :prepared
  end

  test 'successful execution with early exit due to user canceling job' do
    perform_enqueued_jobs(only: WorkflowExecutionPreparationJob) do
      WorkflowExecutionPreparationJob.perform_later(@workflow_execution_canceling)
    end

    assert_enqueued_jobs(0)
    @workflow_execution_canceling.reload.state.to_sym == :canceling
  end

  test 'successful invalid execution' do
    perform_enqueued_jobs(only: WorkflowExecutionPreparationJob) do
      WorkflowExecutionPreparationJob.perform_later(@workflow_execution_completed)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(1, only: WorkflowExecutionPreparationJob)
    @workflow_execution_completed.reload.state.to_sym == :error
  end
end
