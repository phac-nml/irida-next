# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class IntegrationSapporo < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_end_to_end)
  end

  test 'integration sapporo end to end' do
    assert_equal 'initial', @workflow_execution.state
    assert_not @workflow_execution.cleaned?

    WorkflowExecutionPreparationJob.perform_later(@workflow_execution)

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionSubmissionJob)
    assert_equal 'prepared', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionStatusJob)
    assert_equal 'submitted', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(delay_seconds: 10, except: WorkflowExecutionCompletionJob)
    assert_equal 'completing', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially(except: WorkflowExecutionCleanupJob)
    assert_equal 'completed', @workflow_execution.reload.state

    perform_enqueued_jobs_sequentially

    assert_equal 'completed', @workflow_execution.reload.state
    assert @workflow_execution.cleaned?
  end
end
