# frozen_string_literal: true

require 'test_helper'

module Groups
  class WorkflowExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:joan_doe)
      @group = groups(:group_one)
      @workflow_execution = workflow_executions(:workflow_execution_group_shared1)

      Flipper.enable(:workflow_execution_sharing)
    end

    test 'should show a listing of workflow executions for the group' do
      get group_workflow_executions_path(@group)

      assert_response :success
    end

    test 'should not show a listing of workflow executions for the group' do
      sign_in users(:micha_doe)

      get group_workflow_executions_path(@group)

      assert_response :unauthorized
    end

    test 'should not show a listing of group workflow executions for guests' do
      sign_in users(:ryan_doe)

      get group_workflow_executions_path(@group)

      assert_response :unauthorized
    end

    test 'should show workflow execution that was shared to group by the user' do
      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :success
    end

    test 'should show workflow execution that shared to group but not by the user' do
      workflow_execution = workflow_executions(:workflow_execution_group_shared2)

      get group_workflow_execution_path(@group, workflow_execution)

      assert_response :success
    end

    test 'should not show shared workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)

      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show workflow execution that is not shared' do
      workflow_execution = workflow_executions(:workflow_execution_valid)

      get group_workflow_execution_path(@group, workflow_execution)

      assert_response :not_found
    end

    test 'should not show group workflow execution for guests' do
      sign_in users(:ryan_doe)

      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :unauthorized
    end

    test 'should not cancel a workflow if user is not the submitter ' do
      workflow_execution = workflow_executions(:workflow_execution_group_shared_new)

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'should cancel a new workflow with valid params' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_new)

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :success
      # A new workflow goes directly to the canceled state as ga4gh does not know it exists
      assert_equal 'canceled', workflow_execution.reload.state
    end

    test 'should cancel a prepared workflow with valid params' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_prepared)

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :success
      # A prepared workflow goes directly to the canceled state as ga4gh does not know it exists
      assert_equal 'canceled', workflow_execution.reload.state
    end

    test 'should cancel a submitted workflow with valid params' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_submitted)
      assert workflow_execution.submitted?

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :success
      # A submitted workflow goes to the canceling state as ga4gh must be sent a cancel request
      assert_equal 'canceling', workflow_execution.reload.state
    end

    test 'should not cancel a completed workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_completed)
      assert workflow_execution.completed?

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :unprocessable_entity

      assert workflow_execution.completed?
    end

    test 'should cancel a running workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_running)
      assert workflow_execution.running?

      put cancel_group_workflow_execution_path(@group, workflow_execution, format: :turbo_stream)

      assert_response :success
      # A running workflow goes to the canceling state as ga4gh must be sent a cancel request
      assert_equal 'canceling', workflow_execution.reload.state
    end

    test 'submitter should be able to update their shared workflow executions name post launch' do
      update_params = { workflow_execution: { name: 'New Name' } }

      put group_workflow_execution_path(@group, @workflow_execution, format: :turbo_stream),
          params: update_params

      assert_response :success
    end

    test 'non-submitter group member should not be able to update a shared workflow executions name post launch' do
      sign_in users(:james_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put group_workflow_execution_path(@group, @workflow_execution, format: :turbo_stream),
          params: update_params

      assert_response :unauthorized
    end

    test 'non-submitter non group member should not be able to update a shared workflow executions name post launch' do
      sign_in users(:micha_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put group_workflow_execution_path(@group, @workflow_execution, format: :turbo_stream),
          params: update_params

      assert_response :unauthorized
    end

    test 'should not delete a prepared workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_prepared)
      assert workflow_execution.prepared?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should not delete a submitted workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_submitted)
      assert workflow_execution.submitted?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should delete a completed workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_completed)
      assert workflow_execution.completed?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :redirect
      assert_redirected_to group_workflow_executions_path
    end

    test 'should delete an errored workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_error)
      assert workflow_execution.error?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :redirect
      assert_redirected_to group_workflow_executions_path
    end

    test 'should not delete a canceling workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_canceling)
      assert workflow_execution.canceling?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should delete a canceled workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_canceled)
      assert workflow_execution.canceled?
      assert_difference -> { WorkflowExecution.count } => -1,
                        -> { SamplesWorkflowExecution.count } => -1 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :redirect
      assert_redirected_to group_workflow_executions_path
    end

    test 'should not delete a running workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_running)
      assert workflow_execution.running?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'should not delete a new workflow' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_new)
      assert workflow_execution.initial?
      assert_difference -> { WorkflowExecution.count } => 0,
                        -> { SamplesWorkflowExecution.count } => 0 do
        delete group_workflow_execution_path(@group, workflow_execution,
                                             format: :turbo_stream)
      end
      assert_response :unprocessable_entity
    end

    test 'redirect to project workflow executions page when workflow execution is deleted' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_canceled)

      delete group_workflow_execution_path(@group, workflow_execution, redirect: true,
                                                                       format: :turbo_stream)
      assert_response :redirect

      assert_redirected_to group_workflow_executions_path(@group)
    end
  end
end
