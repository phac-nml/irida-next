# frozen_string_literal: true

require 'test_helper'

class PipelinesQueryTest < ActiveSupport::TestCase
  PIPELINES_QUERY = <<~GRAPHQL
    query($workflow_type: String!) {
      pipelines(workflowType: $workflow_type) {
        automatable
        description
        executable
        metadata
        name
        version
        workflowParams
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'pipeline query should work for executable pipelines' do
    workflow_type = 'executable'

    result = IridaSchema.execute(PIPELINES_QUERY, context: { current_user: @user },
                                                  variables: { workflow_type: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['pipelines']

    assert_not_empty data, 'sample type should work'
    assert_equal 4, data.count
    data.each do |pipeline|
      assert_equal true, pipeline['executable']
    end
  end

  test 'pipeline query should work for automatable pipelines' do
    workflow_type = 'automatable'

    result = IridaSchema.execute(PIPELINES_QUERY, context: { current_user: @user },
                                                  variables: { workflow_type: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['pipelines']

    assert_not_empty data, 'sample type should work'
    assert_equal 1, data.count
    data.each do |pipeline|
      assert_equal true, pipeline['automatable']
    end
  end

  test 'pipeline query should work for all pipelines' do
    workflow_type = 'available'

    result = IridaSchema.execute(PIPELINES_QUERY, context: { current_user: @user },
                                                  variables: { workflow_type: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['pipelines']

    assert_not_empty data, 'sample type should work'

    executable_count = 0
    automatable_count = 0
    total_count = 0
    data.each do |pipeline|
      total_count += 1
      executable_count += 1 if pipeline['executable']
      automatable_count += 1 if pipeline['automatable']

      if pipeline['version'] == '1.0.0' # the pipeline that is not in either of the other tests
        assert pipeline['executable'] != true
        assert pipeline['automatable'] != true
      end
    end

    assert_equal 4, executable_count
    assert_equal 1, automatable_count
    assert_equal 5, total_count
  end
end
