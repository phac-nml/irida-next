# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionsQueryTest < ActiveSupport::TestCase
  WORKFLOW_EXECUTIONS_QUERY = <<~GRAPHQL
    query($first: Int) {
      workflowExecutions(first: $first) {
        nodes {
          id
        }
      }
    }
  GRAPHQL

  WORKFLOW_EXECUTIONS_NODE_QUERY = <<~GRAPHQL
    query($workflow_execution_id: ID!) {
      node(id: $workflow_execution_id) {
        ... on WorkflowExecution {
          id
          metadata
          runId
          state
          tags
          workflowEngine
          workflowEngineParameters
          workflowEngineVersion
          workflowParams
          workflowType
          workflowTypeVersion
          workflowUrl
          samples {
            nodes {
              id
            }
          }
          submitter { id }
          submitterId
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'workflow executions query should work' do
    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_QUERY, context: { current_user: @user },
                                                            variables: { first: 1 })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['workflowExecutions']

    assert_not_empty data, 'workflow execution type should work'
    assert_not_empty data['nodes']
  end

  test 'workflow executions nodes query should work' do
    workflow_execution_id = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']['workflowExecutions']['nodes'][0]['id']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']
    assert_not_empty data, 'workflow execution type should work'
    assert_equal 'my_run_id_1', data['runId'], 'workflow execution run id should match'
  end

  test 'workflow executions nodes query for samples should work' do
    workflow_execution_id = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']['workflowExecutions']['nodes'][0]['id']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    data = result['data']['node']

    assert_not_empty data['samples']['nodes'], 'workflow execution samples resolver should work'
    assert_equal 'gid://irida/Sample/21002189', data['samples']['nodes'][0]['id'], 'sample id should match'
  end
end
