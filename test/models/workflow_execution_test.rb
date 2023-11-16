# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @workflow_execution_valid = workflow_executions(:workflow_execution_valid)
    @workflow_execution_invalid_metadata = workflow_executions(:workflow_execution_invalid_metadata)
  end

  test 'valid workflow execution' do
    assert @workflow_execution_valid.valid?
  end

  test 'invalid metadata' do
    assert_not @workflow_execution_invalid_metadata.valid?
    assert_not @workflow_execution_invalid_metadata.metadata.valid?
    assert_not_nil @workflow_execution_invalid_metadata.errors[:metadata]
    assert_equal ['WorkflowMetadata is invalid.'], @workflow_execution_invalid_metadata.errors.full_messages
    assert_not_nil @workflow_execution_invalid_metadata.metadata.errors[:workflow_version]
    assert_equal ["Workflow version can't be blank"], @workflow_execution_invalid_metadata.metadata.errors.full_messages
  end
end
