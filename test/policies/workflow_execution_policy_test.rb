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

    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.read?
  end

  test '#create?' do
    assert @policy.create?
  end

  test '#cancel?' do
    assert @policy.cancel?

    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.cancel?
  end

  test '#destroy?' do
    assert @policy.destroy?

    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.destroy?
  end

  test 'automated scope' do
    project = projects(:project1)

    scoped_automated_workflow_executions = @policy.apply_scope(WorkflowExecution, type: :relation, name: :automated,
                                                                                  scope_options: { project: })

    assert_equal 10, scoped_automated_workflow_executions.count
  end

  test 'user scope' do
    scoped_user_workflow_executions = @policy.apply_scope(WorkflowExecution, type: :relation, name: :user,
                                                                             scope_options: { user: @user })

    assert_equal 14, scoped_user_workflow_executions.count
  end
end
