# frozen_string_literal: true

require 'test_helper'

module Projects
  class WorfklowExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @workflow_execution = workflow_executions(:automated_example_completed)
      @namespace = groups(:group_one)
      @project = projects(:project1)
    end

    test 'should show a listing of workflow executions for the project' do
      get namespace_project_workflow_executions_path(@namespace, @project, format: :turbo_stream)

      assert_response :success
    end

    test 'should not show a listing of workflow executions for the project' do
      sign_in users(:micha_doe)

      get namespace_project_workflow_executions_path(@namespace, @project, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'should show workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :success
    end

    test 'should not show workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should cancel a new workflow with valid params' do
      workflow_execution = workflow_executions(:automated_example_new)

      put cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                           format: :turbo_stream)
      assert_response :success
      # A new workflow goes directly to the canceled state as ga4gh does not know it exists
      assert_equal 'canceled', workflow_execution.reload.state
    end

    test 'should cancel a prepared workflow with valid params' do
      workflow_execution = workflow_executions(:automated_example_prepared)

      put cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                           format: :turbo_stream)
      assert_response :success
      # A prepared workflow goes directly to the canceled state as ga4gh does not know it exists
      assert_equal 'canceled', workflow_execution.reload.state
    end

    test 'should not delete a prepared workflow' do
      workflow_execution = workflow_executions(:automated_example_prepared)
      assert workflow_execution.prepared?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should cancel a submitted workflow with valid params' do
      workflow_execution = workflow_executions(:automated_example_submitted)
      assert workflow_execution.submitted?

      put cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                           format: :turbo_stream)
      assert_response :success
      # A submitted workflow goes to the canceling state as ga4gh must be sent a cancel request
      assert_equal 'canceling', workflow_execution.reload.state
    end

    test 'should not delete a submitted workflow' do
      workflow_execution = workflow_executions(:automated_example_submitted)
      assert workflow_execution.submitted?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should not cancel a completed workflow' do
      workflow_execution = workflow_executions(:automated_example_completed)
      assert workflow_execution.completed?

      put cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                           format: :turbo_stream)
      assert_response :unprocessable_entity

      assert workflow_execution.completed?
    end

    test 'should delete a completed workflow' do
      workflow_execution = workflow_executions(:automated_example_completed)
      assert workflow_execution.completed?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :success
    end

    test 'should delete an errored workflow' do
      workflow_execution = workflow_executions(:automated_example_error)
      assert workflow_execution.error?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :success
    end

    test 'should not delete a canceling workflow' do
      workflow_execution = workflow_executions(:automated_example_canceling)
      assert workflow_execution.canceling?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should delete a canceled workflow' do
      workflow_execution = workflow_executions(:automated_example_canceled)
      assert workflow_execution.canceled?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :success
    end

    test 'should not delete a running workflow' do
      workflow_execution = workflow_executions(:automated_example_running)
      assert workflow_execution.running?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should cancel a running workflow' do
      workflow_execution = workflow_executions(:automated_example_running)
      assert workflow_execution.running?

      put cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                           format: :turbo_stream)
      assert_response :success
      # A running workflow goes to the canceling state as ga4gh must be sent a cancel request
      assert_equal 'canceling', workflow_execution.reload.state
    end

    test 'should not delete a new workflow' do
      workflow_execution = workflow_executions(:automated_example_new)
      assert workflow_execution.initial?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'redirect to project workflow executions page when workflow execution is deleted' do
      workflow_execution = workflow_executions(:automated_example_canceled)

      delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, redirect: true,
                                                                                                 format: :turbo_stream)
      assert_response :redirect

      assert_redirected_to namespace_project_workflow_executions_path(@namespace, @project, format: :html)
    end
  end
end
