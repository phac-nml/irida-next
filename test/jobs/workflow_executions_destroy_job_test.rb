# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionsDestroyJobTest < ActiveJob::TestCase
  def setup
    @workflow_execution1 = workflow_executions(:irida_next_example_completed_DELETE)
    @workflow_execution2 = workflow_executions(:irida_next_example_error_DELETE)
    @workflow_execution3 = workflow_executions(:irida_next_example_canceled_DELETE)
  end

  test 'valid workflow executions pretest' do
    assert @workflow_execution1.valid?
    assert @workflow_execution2.valid?
    assert @workflow_execution3.valid?
  end

  test 'deletion after default 7 days' do
    assert_nil @workflow_execution1.deleted_at
    @workflow_execution1.destroy
    assert_not_nil @workflow_execution1.deleted_at

    travel 9.days

    assert_difference -> { WorkflowExecution.only.count } => -1,
                      -> { WorkflowExecution.only_deleted.count } => -1,
                      -> { SamplesWorkflowExecution.only.count } => -1,
                      -> { SamplesWorkflowExecution.only_deleted.count } => -1 do
      WorkflowExecutionsDestroyJob.perform_now
    end
  end

  test 'deletion after specified 4 days' do
    assert_nil @workflow_execution1.deleted_at
    @workflow_execution1.destroy
    assert_not_nil @workflow_execution1.deleted_at

    travel 6.days

    assert_difference -> { WorkflowExecution.only.count } => -1,
                      -> { WorkflowExecution.only_deleted.count } => -1,
                      -> { SamplesWorkflowExecution.only.count } => -1,
                      -> { SamplesWorkflowExecution.only_deleted.count } => -1 do
      WorkflowExecutionsDestroyJob.perform_now(days_old: 4)
    end
  end

  test 'deletion multiple' do
    assert_nil @workflow_execution1.deleted_at
    assert_nil @workflow_execution2.deleted_at
    assert_nil @workflow_execution3.deleted_at
    @workflow_execution1.destroy
    @workflow_execution2.destroy
    assert_not_nil @workflow_execution1.deleted_at
    assert_not_nil @workflow_execution2.deleted_at
    assert_nil @workflow_execution3.deleted_at

    travel 9.days

    assert_difference -> { WorkflowExecution.only.count } => -2,
                      -> { WorkflowExecution.only_deleted.count } => -2,
                      -> { SamplesWorkflowExecution.only.count } => -2,
                      -> { SamplesWorkflowExecution.only_deleted.count } => -2 do
      WorkflowExecutionsDestroyJob.perform_now
    end
  end

  test 'invalid argument string' do
    assert_raise(Exception) do
      WorkflowExecutionsDestroyJob.perform_now(days_old: 'this is not a number')
    end
  end

  test 'invalid argument negative' do
    assert_raise(Exception) do
      WorkflowExecutionsDestroyJob.perform_now(days_old: -1)
    end
  end

  test 'invalid argument zero' do
    assert_raise(Exception) do
      WorkflowExecutionsDestroyJob.perform_now(days_old: 0)
    end
  end

  test 'invalid argument int as string' do
    assert_raise(Exception) do
      WorkflowExecutionsDestroyJob.perform_now(days_old: '1')
    end
  end
end
