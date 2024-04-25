# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionTest < ActiveSupport::TestCase
  def setup
    @workflow_execution_valid = workflow_executions(:workflow_execution_valid)
    @workflow_execution_invalid_metadata = workflow_executions(:workflow_execution_invalid_metadata)
  end

  test 'valid workflow execution' do
    assert @workflow_execution_valid.valid?
  end

  test 'invalid metadata' do
    assert_not @workflow_execution_invalid_metadata.valid?
    assert_not_nil @workflow_execution_invalid_metadata.errors[:metadata]
    assert_equal(
      ['Metadata root is missing required keys: workflow_version'],
      @workflow_execution_invalid_metadata.errors.full_messages
    )
  end

  test 'state with type enum using key assignment' do
    @workflow_execution_valid.state = :initial
    assert @workflow_execution_valid.initial?

    @workflow_execution_valid.state = :prepared
    assert_not @workflow_execution_valid.initial?
    assert @workflow_execution_valid.prepared?

    @workflow_execution_valid.state = :submitted
    assert_not @workflow_execution_valid.prepared?
    assert @workflow_execution_valid.submitted?

    @workflow_execution_valid.state = :running
    assert_not @workflow_execution_valid.submitted?
    assert @workflow_execution_valid.running?

    @workflow_execution_valid.state = :completing
    assert_not @workflow_execution_valid.running?
    assert @workflow_execution_valid.completing?

    @workflow_execution_valid.state = :completed
    assert_not @workflow_execution_valid.completing?
    assert @workflow_execution_valid.completed?

    @workflow_execution_valid.state = :error
    assert_not @workflow_execution_valid.completed?
    assert @workflow_execution_valid.error?

    @workflow_execution_valid.state = :canceling
    assert_not @workflow_execution_valid.error?
    assert @workflow_execution_valid.canceling?

    @workflow_execution_valid.state = :canceled
    assert_not @workflow_execution_valid.canceling?
    assert @workflow_execution_valid.canceled?
  end

  test 'state with type enum using int assignment' do
    @workflow_execution_valid.state = 0
    assert @workflow_execution_valid.initial?

    @workflow_execution_valid.state = 1
    assert_not @workflow_execution_valid.initial?
    assert @workflow_execution_valid.prepared?

    @workflow_execution_valid.state = 2
    assert_not @workflow_execution_valid.prepared?
    assert @workflow_execution_valid.submitted?

    @workflow_execution_valid.state = 3
    assert_not @workflow_execution_valid.submitted?
    assert @workflow_execution_valid.running?

    @workflow_execution_valid.state = 4
    assert_not @workflow_execution_valid.running?
    assert @workflow_execution_valid.completing?

    @workflow_execution_valid.state = 5
    assert_not @workflow_execution_valid.completing?
    assert @workflow_execution_valid.completed?

    @workflow_execution_valid.state = 6
    assert_not @workflow_execution_valid.completed?
    assert @workflow_execution_valid.error?

    @workflow_execution_valid.state = 7
    assert_not @workflow_execution_valid.error?
    assert @workflow_execution_valid.canceling?

    @workflow_execution_valid.state = 8
    assert_not @workflow_execution_valid.canceling?
    assert @workflow_execution_valid.canceled?
  end
end
