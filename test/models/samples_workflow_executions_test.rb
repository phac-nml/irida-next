# frozen_string_literal: true

require 'test_helper'

class SamplesWorkflowExecutionsTest < ActiveSupport::TestCase
  def setup
    @samples_workflow_executions_valid = samples_workflow_executions(
      :samples_workflow_executions_valid
    )
    @samples_workflow_executions_invalid_no_sample = samples_workflow_executions(
      :samples_workflow_executions_invalid_no_sample
    )
    @samples_workflow_executions_invalid_no_workflow_execution = samples_workflow_executions(
      :samples_workflow_executions_invalid_no_workflow_execution
    )
  end

  test 'valid samples workflow executions' do
    assert @samples_workflow_executions_valid.valid?
  end

  test 'invalid no sample' do
    assert_not @samples_workflow_executions_invalid_no_sample.valid?
    assert_not_nil @samples_workflow_executions_invalid_no_sample.errors
    assert_equal ['Sample must exist'], @samples_workflow_executions_invalid_no_sample.errors.full_messages
  end

  test 'invalid no workflow execution' do
    assert_not @samples_workflow_executions_invalid_no_workflow_execution.valid?
    assert_not_nil @samples_workflow_executions_invalid_no_workflow_execution.errors
    assert_equal(
      ['Workflow execution must exist'],
      @samples_workflow_executions_invalid_no_workflow_execution.errors.full_messages
    )
  end
end
