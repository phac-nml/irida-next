# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionPolicyTest < ActiveSupport::TestCase
  def setup
    @details = {}
    @user = users(:john_doe)
    @automation_bot_user = users(:project1_automation_bot)
    @workflow_execution = workflow_executions(:irida_next_example_prepared)
    @policy = WorkflowExecutionPolicy.new(@workflow_execution, user: @user)
  end

  test '#read?' do
    assert @policy.apply(:read?)

    user = users(:ryan_doe)
    policy = WorkflowExecutionPolicy.new(@workflow_execution, user:)

    assert policy.apply(:read?)

    user = users(:project1_automation_bot)
    user_incorrect_permissions = users(:micha_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:read?)

    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert policy.apply(:read?)

    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:read?)
  end

  test '#create?' do
    assert @policy.apply(:create?)

    user_incorrect_permissions = users(:ryan_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:create?)
  end

  test 'update?' do
    assert @policy.apply(:update?)

    user = users(:james_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user)

    assert policy.apply(:update?)

    user = users(:ryan_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user)

    assert_not policy.apply(:update?)
  end

  test 'edit?' do
    assert @policy.apply(:edit?)

    user = users(:james_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user)

    assert policy.apply(:edit?)

    user = users(:ryan_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user)

    assert_not policy.apply(:edit?)
  end

  test '#cancel?' do
    assert @policy.apply(:cancel?)

    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:cancel?)

    automated_workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(automated_workflow_execution, user: @user)

    assert policy.apply(:cancel?)

    user_incorrect_permissions = users(:ryan_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:cancel?)
  end

  test '#destroy?' do
    assert @policy.apply(:destroy?)

    user = users(:project1_automation_bot)
    user_incorrect_permissions = users(:ryan_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:destroy?)

    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert policy.apply(:destroy?)

    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:destroy?)
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

    assert_equal 20, scoped_user_workflow_executions.count
  end

  test 'automated and shared scope' do
    project = projects(:project1)

    workflow_executions = @policy.apply_scope(WorkflowExecution, type: :relation, name: :automated_and_shared,
                                                                 scope_options: { project: })

    assert_equal 12, workflow_executions.count
  end

  test 'user and shared scope' do
    workflow_executions = @policy.apply_scope(WorkflowExecution, type: :relation, name: :user_and_shared,
                                                                 scope_options: { user: @user })

    assert_equal 22, workflow_executions.count
    assert workflow_executions.exists?(run_id: 'my_run_id_shared_2')
  end
end
