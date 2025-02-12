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

    # shared workflow execution
    # user is project member
    user = users(:ryan_doe)
    workflow_execution = workflow_executions(:workflow_execution_shared2)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:read?)

    # user is not project member
    user_incorrect_permissions = users(:micha_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:read?)

    # automated workflow execution
    # user is project automation bot
    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:read?)

    # user is project creator
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert policy.apply(:read?)

    # user with incorrect permissions
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

    # automated workflow execution
    # user is ANALYST
    workflow_execution = workflow_executions(:automated_workflow_execution)
    user = users(:james_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:update?)

    # user is GUEST
    user = users(:ryan_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:update?)

    # shared workflow execution
    # user is submitter
    workflow_execution = workflow_executions(:workflow_execution_shared2)
    user = users(:james_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:update?)

    # user is member of project
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert_not policy.apply(:update?)

    # user is not member of project
    user = users(:micha_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:update?)
  end

  test 'edit?' do
    assert @policy.apply(:edit?)

    # automated workflow execution
    # user is ANALYST
    user = users(:james_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:edit?)

    # user is GUEST
    user = users(:ryan_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:edit?)

    # shared workflow execution
    # user is submitter
    workflow_execution = workflow_executions(:workflow_execution_shared2)
    user = users(:james_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:edit?)

    # user is member of project
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert_not policy.apply(:edit?)

    # user is not member of project
    user = users(:micha_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:edit?)
  end

  test '#cancel?' do
    assert @policy.apply(:cancel?)

    # automated workflow execution
    # user is project automation bot
    user = users(:project1_automation_bot)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:cancel?)

    # user is project OWNER
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert policy.apply(:cancel?)

    # user with incorrect permissions
    user_incorrect_permissions = users(:ryan_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:cancel?)

    # shared workflow execution
    # user is submitter
    workflow_execution = workflow_executions(:workflow_execution_shared2)
    user = users(:james_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:cancel?)

    # user is member of project
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert_not policy.apply(:cancel?)

    # user is not member of project
    user = users(:micha_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:cancel?)
  end

  test '#destroy?' do
    assert @policy.apply(:destroy?)

    # automated workflow execution
    # user is project automation bot
    user = users(:project1_automation_bot)
    user_incorrect_permissions = users(:ryan_doe)
    workflow_execution = workflow_executions(:automated_workflow_execution)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:destroy?)

    # user is project OWNER
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert policy.apply(:destroy?)

    # user with incorrect permissions
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: user_incorrect_permissions)

    assert_not policy.apply(:destroy?)

    # shared workflow execution
    # user is submitter
    workflow_execution = workflow_executions(:workflow_execution_shared2)
    user = users(:james_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert policy.apply(:cancel?)

    # user is member of project
    policy = WorkflowExecutionPolicy.new(workflow_execution, user: @user)

    assert_not policy.apply(:cancel?)

    # user is not member of project
    user = users(:micha_doe)
    policy = WorkflowExecutionPolicy.new(workflow_execution, user:)

    assert_not policy.apply(:cancel?)
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

  test 'group shared scope' do
    group = groups(:group_one)

    workflow_executions = @policy.apply_scope(WorkflowExecution, type: :relation, name: :group_shared,
                                                                 scope_options: { group: })

    assert_equal 2, workflow_executions.count
  end
end
