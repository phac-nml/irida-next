# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should redirect to dashboard projects on html request' do
      sign_in users(:john_doe)

      get pipeline_selection_workflow_executions_submission_index_path(format: :html)
      assert_redirected_to dashboard_projects_path
    end

    test 'should render pipeline selection on turbo stream request' do
      sign_in users(:john_doe)

      get pipeline_selection_workflow_executions_submission_index_path(format: :turbo_stream)
      assert_response :ok
    end
  end
end
