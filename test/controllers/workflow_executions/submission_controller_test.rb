# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should render pipeline selection on turbo stream request' do
      sign_in users(:john_doe)

      get pipeline_selection_workflow_executions_submissions_path(format: :turbo_stream)
      assert_response :ok
    end
  end
end
