# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionJobTest < ActiveJobTestCase
  def setup
    @workflow_execution_submitted = workflow_executions(:irida_next_example_submitted)
    @workflow_execution_prepared = workflow_executions(:irida_next_example_prepared)
    @workflow_execution_new = workflow_executions(:irida_next_example_new)
    @workflow_execution_completed = workflow_executions(:irida_next_example_completed)
    @workflow_execution_missing_run_id = workflow_executions(:workflow_execution_missing_run_id)
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'nil workflow execution' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(nil)
  end

  test 'missing namespace' do
    @workflow_execution_new.namespace = nil
    assert_not WorkflowExecutionJob.new.validate_initial_state(@workflow_execution_new)
  end

  test 'state in expected states' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, %i[prepared submitted]
    )
  end

  test 'state not in expected states' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_completed, %i[prepared submitted]
    )
  end

  test 'run id validation success' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, validate_run_id: true
    )
  end

  test 'run id validation failure' do
    assert_not WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_missing_run_id, validate_run_id: true
    )
  end

  test 'all arguments' do
    assert WorkflowExecutionJob.new.validate_initial_state(
      @workflow_execution_submitted, %i[prepared submitted], validate_run_id: true
    )
  end
end
