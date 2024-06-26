# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionCleanupJobTest < ActiveJobTestCase
  test 'successful job on completed workflow execution' do
    # TODO: Temp
    skip
    workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_performed_jobs 1
    assert workflow_execution.reload.cleaned?
  end

  test 'successful job on canceled workflow execution' do
    # TODO: Temp
    skip
    workflow_execution = workflow_executions(:irida_next_example_canceled_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_performed_jobs 1
    assert workflow_execution.reload.cleaned?
  end

  test 'successful job on error workflow execution' do
    # TODO: Temp
    skip
    workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_performed_jobs 1
    assert workflow_execution.reload.cleaned?
  end

  test 'failed job on running workflow execution' do
    # TODO: Temp
    skip
    workflow_execution = workflow_executions(:irida_next_example_running)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_performed_jobs 1
    assert_not workflow_execution.reload.cleaned?
  end
end
