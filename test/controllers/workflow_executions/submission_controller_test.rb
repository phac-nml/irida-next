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

    test 'create submission' do
      sign_in users(:john_doe)
      project1 = projects(:project1)
      sample1 = samples(:sample1)
      post workflow_executions_submissions_path(namespace_id: project1.namespace.id,
                                                workflow_name: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.3',
                                                samples: [sample1.id], format: :turbo_stream)
      assert_response :ok
    end
  end
end
