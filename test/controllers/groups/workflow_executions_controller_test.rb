require "test_helper"

module Groups
  class WorkflowExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @workflow_execution = workflow_executions(:automated_example_completed)
      @namespace = groups(:group_one)
      @project = projects(:project1)
      @group = groups(:group_one)
    end

    test 'should show a listing of workflow executions for the project' do
      get group_workflow_executions_path(@group)

      assert_response :success
    end
  end
end
