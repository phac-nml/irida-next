# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      @project = projects(:project1)
    end

    test 'should render pipeline selection on turbo stream request' do
      get pipeline_selection_workflow_executions_submissions_path(format: :turbo_stream)
      assert_response :ok
    end

    test 'create submission' do
      sample1 = samples(:sample1)
      post workflow_executions_submissions_path(namespace_id: @project.namespace.id,
                                                pipeline_id: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.3',
                                                samples: [sample1.id], format: :turbo_stream)

      assert_response :ok
    end

    test '@fields in create' do
      post workflow_executions_submissions_path(format: :turbo_stream,
                                                pipeline_id: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.2', namespace_id: @group.id)
      assert_response :ok
      assert_equal ['metadata field with spaces', 'metadatafield1', 'metadatafield2', 'unique.metadata.field'],
                   @controller.instance_eval('@fields', __FILE__, __LINE__)
    end

    test '@workflows are sorted' do
      get pipeline_selection_workflow_executions_submissions_path(format: :turbo_stream)
      assert_response :ok

      workflows = @controller.instance_variable_get('@workflows')
      # workflows is an array of [key, pipeline] pairs, sorted by pipeline
      assert(workflows.each_cons(2).all? { |(_, a), (_, b)| a <= b })
    end
  end
end
