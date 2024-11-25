# frozen_string_literal: true

require 'test_helper'

class PipelineQueryTest < ActiveSupport::TestCase
  PIPELINE_QUERY = <<~GRAPHQL
    query($workflow_name: String!, $workflow_version: String!, $workflow_type: String!) {
      pipeline(workflowName: $workflow_name, workflowVersion: $workflow_version, workflowType: $workflow_type) {
        automatable
        description
        engine
        engineVersion
        executable
        metadata
        name
        type
        typeVersion
        url
        version
        workflowParams
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'pipeline query should work' do
    workflow_name = 'phac-nml/iridanextexample'
    workflow_version = '1.0.3'
    workflow_type = 'executable'

    result = IridaSchema.execute(PIPELINE_QUERY, context: { current_user: @user },
                                                 variables: { workflow_name:, workflow_version:, workflow_type: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['pipeline']

    assert_not_empty data, 'sample type should work'
    assert_equal workflow_name, data['name']
    assert_equal workflow_version, data['version']
    assert_equal true, data['executable']
    assert_equal false, data['automatable']
  end
end
