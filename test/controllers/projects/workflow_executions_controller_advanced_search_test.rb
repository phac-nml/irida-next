# frozen_string_literal: true

require 'test_helper'

module Projects
  class WorkflowExecutionsControllerAdvancedSearchTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @namespace = groups(:group_one)
      @project = projects(:project1)
      @workflow_execution = workflow_executions(:automated_example_completed)
    end

    test 'index action renders successfully' do
      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :success
    end

    test 'index action with advanced search params renders successfully' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
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
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: { name_or_id_cont: 'example' }
      }

      assert_response :success
    end

    test 'index action with advanced search and simple search together renders successfully' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
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

    test 'index action with advanced search by state field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
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

    test 'index action with advanced search by run_id field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'run_id', operator: '=', value: @workflow_execution.run_id }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search by id field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'id', operator: '=', value: @workflow_execution.id.to_s }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search by created_at field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'created_at', operator: '>=', value: '2024-01-01' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search by updated_at field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'updated_at', operator: '<=', value: '2024-12-31' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search by workflow_name JSONB field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'workflow_name', operator: '=', value: 'phac-nml/iridanextexample' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search by workflow_version JSONB field' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'workflow_version', operator: '=', value: '1.0.0' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search using in operator' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: 'in', value: ['completed', 'running'] }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search using not_in operator' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: 'not_in', value: ['canceled', 'error'] }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search using exists operator' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'workflow_name', operator: 'exists', value: '' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search using not_exists operator' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'workflow_version', operator: 'not_exists', value: '' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with multiple conditions in same group' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: '=', value: 'completed' },
                '1' => { field: 'id', operator: '>=', value: '1' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with multiple groups (OR logic)' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: '=', value: 'completed' }
              }
            },
            '1' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: '=', value: 'running' }
              }
            }
          }
        }
      }

      assert_response :success
    end

    test 'index action with advanced search and pagination' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          groups_attributes: {
            '0' => {
              'conditions_attributes' => {
                '0' => { field: 'state', operator: '=', value: 'completed' }
              }
            }
          }
        },
        page: 1,
        limit: 10
      }

      assert_response :success
    end

    test 'index action with validation errors renders successfully' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
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

    test 'index action with sort parameters renders successfully' do
      get namespace_project_workflow_executions_path(@namespace, @project), params: {
        q: {
          sort: 'name asc'
        }
      }

      assert_response :success
    end
  end
end
