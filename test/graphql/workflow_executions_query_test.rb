# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionsQueryTest < ActiveSupport::TestCase
  WORKFLOW_EXECUTIONS_QUERY = <<~GRAPHQL
    query($first: Int) {
      workflowExecutions(first: $first) {
        nodes {
          id
          runId
          samples {
            edges {
              node {
                id
              }
            }
          }
        }
      }
    }
  GRAPHQL

  WORKFLOW_EXECUTIONS_NODE_QUERY = <<~GRAPHQL
    query($workflow_execution_id: ID!) {
      node(id: $workflow_execution_id) {
        ... on WorkflowExecution {
          id
          blobRunDirectory
          cleaned
          httpErrorCode
          metadata
          runId
          state
          submitter {
            id
            email
          }
          submitterId
          tags
          workflowEngine
          workflowEngineParameters
          workflowEngineVersion
          workflowParams
          workflowType
          workflowTypeVersion
          workflowUrl
          samples {
            edges {
              node {
                id
              }
            }
          }
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
    prelim_query = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']

    workflow_execution_id = prelim_query['workflowExecutions']['nodes'][0]['id']
    workflow_execution_run_id = prelim_query['workflowExecutions']['nodes'][0]['runId']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['node']
    assert_not_empty data, 'workflow execution type should work'
    assert_equal workflow_execution_run_id, data['runId'], 'workflow execution run id should match'
  end

  test 'workflow executions nodes query for samples should work' do
    prelim_query = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']

    workflow_execution_id = prelim_query['workflowExecutions']['nodes'][0]['id']
    sample_id = prelim_query['workflowExecutions']['nodes'][0]['samples']['edges'][0]['node']['id']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    data = result['data']['node']

    assert_not_empty data['samples']['edges'], 'workflow execution samples resolver should work'
    assert_equal sample_id, data['samples']['edges'][0]['node']['id'], 'sample id should match'
  end

  test 'workflow executions nodes query for metadata though resolver should work' do
    prelim_query = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']

    workflow_execution_id = prelim_query['workflowExecutions']['nodes'][0]['id']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    data = result['data']['node']

    exp_metadata = { 'workflow_name' => 'wn1', 'workflow_version' => 'wv1' }
    assert_equal exp_metadata, data['metadata']
  end

  test 'workflow executions nodes query for state should translate from enum' do
    prelim_query = IridaSchema.execute(
      WORKFLOW_EXECUTIONS_QUERY,
      context: { current_user: @user },
      variables: { first: 1 }
    )['data']

    workflow_execution_id = prelim_query['workflowExecutions']['nodes'][0]['id']

    result = IridaSchema.execute(WORKFLOW_EXECUTIONS_NODE_QUERY, context: { current_user: @user },
                                                                 variables: { workflow_execution_id: })

    data = result['data']['node']

    # We should have a string translated from the enum, not an integer
    assert_equal 'initial', data['state']
  end
end
