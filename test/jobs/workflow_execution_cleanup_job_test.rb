# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionCleanupJobTest < ActiveJobTestCase
  test 'successful job on completed workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
  end

  test 'successful job on canceled workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_canceled_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
  end

  test 'successful job on error workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
  end

  test 'failed job on running workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_running)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_not workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
  end
end
