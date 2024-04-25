# frozen_string_literal: true

require 'test_helper'

class AutomatedWorkflowExecutionTest < ActiveSupport::TestCase
  def setup
    @valid_automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    @invalid_metadata_automated_workflow_execution = automated_workflow_executions(:invalid_metadata_automated_workflow_execution)
  end

  test 'valid automated workflow execution' do
    assert @valid_automated_workflow_execution.valid?
  end

  test 'invalid metadata' do
    assert_not @invalid_metadata_automated_workflow_execution.valid?
    assert_not_nil @invalid_metadata_automated_workflow_execution.errors[:metadata]
    assert_equal(
      ['Metadata root is missing required keys: workflow_version'],
      @invalid_metadata_automated_workflow_execution.errors.full_messages
    )
  end
end
