# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @workflow_execution = workflow_executions(:irida_next_example_prepared)
    @policy = WorkflowExecutionPolicy.new(@workflow_execution, user: @user)
    @details = {}
  end

  test '#read?' do
    assert @policy.read?
  end

  test '#create?' do
    assert @policy.create?
  end

  test '#cancel?' do
    assert @policy.cancel?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end
end
