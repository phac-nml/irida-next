# frozen_string_literal: true

require 'test_helper'

module Groups
  class WorkflowExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      @workflow_execution = workflow_executions(:workflow_execution_group_shared1)
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

    test 'should not show project workflow execution for guests' do
      sign_in users(:ryan_doe)

      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :unauthorized
    end
  end
end
