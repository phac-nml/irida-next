# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'not destroy prepared workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_prepared)
      assert workflow_execution.prepared?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(workflow_execution, @user).execute
      end
    end

    test 'destroy completed workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_completed)
      assert workflow_execution.completed?

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(workflow_execution, @user).execute
      end
    end

    test 'destroy error workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_error)
      assert workflow_execution.error?

      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1,
                        -> { Sample.count } => 0 do
        WorkflowExecutions::DestroyService.new(workflow_execution, @user).execute
      end
    end

    test 'not destroy canceling workflow execution' do
      workflow_execution = workflow_executions(:irida_next_example_canceling)
      assert workflow_execution.canceling?

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        WorkflowExecutions::DestroyService.new(workflow_execution, @user).execute
      end
    end
  end
end
