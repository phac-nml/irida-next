# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancelServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'cancel submitted workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_submitted)

      assert 'submitted', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_enqueued_jobs(1, only: WorkflowExecutionCancelationJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel running workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_running)

      assert 'running', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_enqueued_jobs(1, only: WorkflowExecutionCancelationJob)

      assert_equal 'canceling', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel prepared workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_prepared)

      assert 'prepared', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)

      assert_equal 'canceled', @workflow_execution.reload.state
      assert_not @workflow_execution.cleaned?
    end

    test 'cancel initial workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example_new)

      assert 'initial', @workflow_execution.state

      assert WorkflowExecutions::CancelService.new(@workflow_execution, @user).execute

      assert_no_enqueued_jobs

      assert_equal 'canceled', @workflow_execution.reload.state
      assert @workflow_execution.cleaned?
    end
  end
end
