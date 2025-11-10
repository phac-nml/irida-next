# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionsControllerAdvancedSearchTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:john_doe)
    @namespace = namespaces_user_namespaces(:john_doe_namespace)
    @workflow_execution = workflow_executions(:irida_next_example_completed)
  end

  test 'index action renders successfully' do
    get workflow_executions_path

    assert_response :success
  end

  test 'index action with advanced search params renders successfully' do
    get workflow_executions_path, params: {
      q: {
        groups_attributes: {
          '0' => {
            'conditions_attributes' => {
              '0' => { field: 'name', operator: 'contains', value: 'example' }
            }
          }
        }
      }
    }

    assert_response :success
  end

  test 'index action with simple search params renders successfully' do
    get workflow_executions_path, params: {
      q: { name_or_id_cont: 'example' }
    }

    assert_response :success
  end

  test 'index action with advanced search and simple search together renders successfully' do
    get workflow_executions_path, params: {
      q: {
        name_or_id_cont: 'test',
        groups_attributes: {
          '0' => {
            'conditions_attributes' => {
              '0' => { field: 'state', operator: '=', value: 'completed' }
            }
          }
        }
      }
    }

    assert_response :success
  end

  test 'index action with sort parameters renders successfully' do
    get workflow_executions_path, params: {
      q: {
        sort: 'name asc'
      }
    }

    assert_response :success
  end

  test 'index action with validation errors renders successfully' do
    get workflow_executions_path, params: {
      q: {
        groups_attributes: {
          '0' => {
            'conditions_attributes' => {
              '0' => { field: 'invalid_field', operator: '=', value: 'test' }
            }
          }
        }
      }
    }

    assert_response :success
  end
end
