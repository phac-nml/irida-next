# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/faraday_test_helpers'

class WorkflowExecutionCleanupJobTest < ActiveJob::TestCase
  include FaradayTestHelpers

  test 'successful job on completed workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_completed_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
  end

  test 'successful job on canceled workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_canceled_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
    assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
  end

  test 'successful job on error workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
    assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
  end

  test 'successful job on error workflow execution with missing namespace' do
    workflow_execution = workflow_executions(:irida_next_example_error_unclean_DELETE)

    workflow_execution.namespace = nil
    workflow_execution.save
    assert_enqueued_jobs(2, only: Turbo::Streams::BroadcastStreamJob)
    assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)

    assert_nil workflow_execution.namespace
    assert_equal 'error', workflow_execution.state
    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(4, only: Turbo::Streams::BroadcastStreamJob) # 2 got queued from setting the namespace to nil
    assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
  end

  test 'failed job on running workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_running)

    assert_not workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert_not workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(0)
  end

  test 'failed job on cleaned workflow execution' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    assert workflow_execution.cleaned?

    perform_enqueued_jobs(only: WorkflowExecutionCleanupJob) do
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    end

    assert workflow_execution.reload.cleaned?

    assert_performed_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_enqueued_jobs(0)
  end
end
