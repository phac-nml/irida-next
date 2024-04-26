# frozen_string_literal: true

require 'test_helper'

module Projects
  class AutomatedWorkflowExecutionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'can get the listing of automated workflow executions for a project' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_automated_workflow_executions_path(namespace, project)

      assert_response :success
    end

    test 'can create a automated workflow execution for a project' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project2)

      post namespace_project_automated_workflow_executions_path(namespace, project),
           params: { automated_workflow_execution: {
             metadata: { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
             workflow_params: { assembler: 'stub' },
             email_notification: true,
             update_samples: true
           }, format: :turbo_stream }

      assert_response :success
    end

    test 'cannot create a automated workflow execution for a project with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)
      project = projects(:project2)

      post namespace_project_automated_workflow_executions_path(namespace, project),
           params: { automated_workflow_execution: {
             metadata: { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
             workflow_params: { assembler: 'stub' },
             email_notification: true,
             update_samples: true
           }, format: :turbo_stream }

      assert_response :unauthorized
    end

    test 'can update a automated workflow execution for a project' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      patch namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution),
            params: {
              automated_workflow_execution: {
                workflow_params: { assembler: 'experimental' }
              },
              format: :turbo_stream
            }

      assert_response :success
    end

    test 'cannot update a automated workflow execution for a project with inocrrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      patch namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution),
            params: {
              automated_workflow_execution: {
                workflow_params: { assembler: 'experimental' }
              },
              format: :turbo_stream
            }

      assert_response :unauthorized
    end

    test 'can destroy a automated workflow execution for a project' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      delete namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution,
                                                                 format: :turbo_stream)

      assert_response :success
    end

    test 'cannot destroy a automated workflow execution for a project with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      delete namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution,
                                                                 format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'can get the new page to create a automated workflow execution for a project' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get new_namespace_project_automated_workflow_execution_path(namespace, project)

      assert_response :success
    end

    test 'can get the edit page to create a automated workflow execution for a project' do
      sign_in users(:john_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      namespace = groups(:group_one)
      project = projects(:project1)

      get edit_namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution)

      assert_response :success
    end

    test 'can get the show page to create a automated workflow execution for a project' do
      sign_in users(:john_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_automated_workflow_execution_path(namespace, project, automated_workflow_execution)

      assert_response :success
    end
  end
end
