# frozen_string_literal: true

require 'test_helper'

module Projects
  class WorkflowExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @workflow_execution = workflow_executions(:automated_example_completed)
      @namespace = groups(:group_one)
      @project = projects(:project1)

      Flipper.enable(:delete_multiple_workflows)
    end

    test 'should show a listing of workflow executions for the project' do
      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :success

      w3c_validate 'Project Workflow Executions Page'
    end

    test 'should not show a listing of workflow executions for the project' do
      sign_in users(:micha_doe)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :unauthorized
    end

    test 'should not show a listing of project workflow executions for guests' do
      sign_in users(:ryan_doe)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :unauthorized
    end

    test 'should show workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :success

      w3c_validate 'Project Workflow Execution Show Page'
    end

    test 'should show shared workflow execution' do
      workflow_execution = workflow_executions(:workflow_execution_shared1)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :success

      w3c_validate 'Project Workflow Execution Show Page'
    end

    test 'should not show shared workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)
      workflow_execution = workflow_executions(:workflow_execution_shared1)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show workflow execution that is not shared' do
      workflow_execution = workflow_executions(:workflow_execution_valid)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :not_found
    end

    test 'should not show workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show project workflow execution for guests' do
      sign_in users(:ryan_doe)
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
      assert_response :redirect
      assert_redirected_to namespace_project_workflow_executions_path
    end

    test 'should delete an errored workflow' do
      workflow_execution = workflow_executions(:automated_example_error)
      assert workflow_execution.error?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution,
                                                         format: :turbo_stream)
      end
      assert_response :redirect
      assert_redirected_to namespace_project_workflow_executions_path
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
      assert_response :redirect
      assert_redirected_to namespace_project_workflow_executions_path
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

      assert_redirected_to namespace_project_workflow_executions_path(@namespace, @project)
    end

    test 'analyst or higher access level can update workflow execution name post launch' do
      update_params = { workflow_execution: { name: 'New Name' } }

      put namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution, format: :turbo_stream),
          params: update_params

      assert_response :success
    end

    test 'access level less than analyst cannot update workflow execution name post launch for an automated workflow' do
      sign_in users(:ryan_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution, format: :turbo_stream),
          params: update_params

      assert_response :unauthorized
    end

    test 'should open destroy_multiple_confirmation' do
      get destroy_multiple_confirmation_namespace_project_workflow_executions_path(
        @namespace, @project, format: :turbo_stream
      )

      assert_response :success
    end

    test 'should not open destroy_multiple_confirmation due to unauthorized access' do
      sign_in users(:ryan_doe)
      get destroy_multiple_confirmation_namespace_project_workflow_executions_path(
        @namespace, @project, format: :turbo_stream
      )

      assert_response :unauthorized
    end

    test 'should destroy multiple workflows at once' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2 do
                          delete destroy_multiple_namespace_project_workflow_executions_path(
                            @namespace,
                            @project,
                            format: :turbo_stream
                          ),
                                 params: { destroy_multiple:
                                          { workflow_execution_ids: [error_workflow.id, canceled_workflow.id] } }
                        end
      assert_response :success
    end

    test 'should partially destroy multiple workflows at once' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)
      running_workflow = workflow_executions(:automated_example_running)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2 do
                          delete destroy_multiple_namespace_project_workflow_executions_path(
                            @namespace,
                            @project,
                            format: :turbo_stream
                          ),
                                 params: {
                                   destroy_multiple: {
                                     workflow_execution_ids: [error_workflow.id, canceled_workflow.id,
                                                              running_workflow.id]
                                   }
                                 }
                        end
      assert_response :multi_status
    end

    test 'should not destroy multiple non-deletable workflows' do
      running_workflow = workflow_executions(:automated_example_running)
      new_workflow = workflow_executions(:automated_example_new)
      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        delete destroy_multiple_namespace_project_workflow_executions_path(
          @namespace,
          @project,
          format: :turbo_stream
        ),
               params: {
                 destroy_multiple: { workflow_execution_ids: [running_workflow.id, new_workflow.id] }
               }
      end
      assert_response :unprocessable_entity
    end

    test 'should not destroy workflows if unauthorized' do
      sign_in users(:ryan_doe)
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)

      assert_no_difference -> { WorkflowExecution.count },
                           -> { SamplesWorkflowExecution.count } do
        delete destroy_multiple_namespace_project_workflow_executions_path(
          @namespace,
          @project,
          format: :turbo_stream
        ),
               params: {
                 destroy_multiple: { workflow_execution_ids: [canceled_workflow.id, error_workflow.id] }
               }
      end

      assert_response :unauthorized
    end
  end
end
