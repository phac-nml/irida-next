require 'test_helper'

module WorkflowExecutions
  class SubmissionControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should redirect to dashboard projects on html request' do
      sign_in(:john_doe)
      get workflow_executions_selection_path
      assert_redirected_to dashboard_projects_path
    end
  end
end
