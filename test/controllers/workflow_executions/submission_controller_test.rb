# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test '@fields in create' do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      post workflow_executions_submissions_path(format: :turbo_stream,
                                                pipeline_id: 'phac-nml/iridanextexample',
                                                workflow_version: '1.0.2', namespace_id: @group.id)
      assert_response :ok
      assert_equal ['metadata field with spaces', 'metadatafield1', 'metadatafield2', 'unique.metadata.field'],
                   @controller.instance_eval('@fields', __FILE__, __LINE__)
    end
  end
end
