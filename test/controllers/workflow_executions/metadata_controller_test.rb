# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class MetadataControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:metadata_doe)
      sample61 = samples(:sample61)
      sample62 = samples(:sample62)
      project_namespace = projects(:projectMetadata).namespace
      @expected_feature_flag_params = {
        metadata_fields: { 'metadata_1' => 'example_float', 'metadata_2' => 'example_integer' }.to_json,
        sample_ids: "#{sample61.id},#{sample62.id}",
        namespace_id: project_namespace.id
      }

      @expected_no_feature_flag_params = {
        header: 'metadata_1',
        sample_ids: [sample61.id, sample62.id],
        field: 'example_float',
        namespace_id: project_namespace.id
      }
    end

    test 'metadata values' do
      post fields_workflow_executions_metadata_path(format: :turbo_stream), params: @expected_feature_flag_params

      assert_response :ok
    end

    test 'unauthorized fields' do
      login_as users(:ryan_doe)
      post fields_workflow_executions_metadata_path(format: :turbo_stream), params: @expected_feature_flag_params

      assert_response :unauthorized
    end
  end
end
