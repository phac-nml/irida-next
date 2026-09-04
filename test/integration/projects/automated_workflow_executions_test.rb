# frozen_string_literal: true

require 'test_helper'

module Projects
  class AutomatedWorkflowExecutionsTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:john_doe)
      sign_in @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
    end

    test 'can see a table listing of automated workflow executions for a project' do
      get namespace_project_automated_workflow_executions_path(@namespace, @project)
      assert_response :success

      assert_select 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_select 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')
      assert_select 'button',
                    text: I18n.t(:'projects.automated_workflow_executions.index.add_new_automated_workflow_execution')

      get namespace_project_automated_workflow_executions_path(@namespace, @project, format: :turbo_stream)
      assert_response :success

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select 'tr', count: 2
        end
      end
    end

    test 'cannot see the automated workflow execution page without proper permissions' do
      sign_out @user
      user_without_permissions = users(:jane_doe)
      sign_in user_without_permissions

      get namespace_project_automated_workflow_executions_path(@namespace, @project)
      assert_response :unauthorized

      assert_select 'h1', text: I18n.t(:'application.errors.access_denied')
    end

    test 'can see an empty state for table listing of automated workflow executions for a project' do
      project = projects(:project2)
      get namespace_project_automated_workflow_executions_path(@namespace, project)

      assert_response :success
      assert_select 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_select 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      get namespace_project_automated_workflow_executions_path(@namespace, project), as: :turbo_stream
      assert_response :success

      assert_select 'div.empty_state_message'

      assert_select 'table', count: 0
    end

    test 'can configure a new automated workflow execution for a project' do
      get namespace_project_automated_workflow_executions_path(@namespace, @project)

      assert_response :success
      assert_select 'button',
                    text: I18n.t(:'projects.automated_workflow_executions.index.add_new_automated_workflow_execution')

      get new_namespace_project_automated_workflow_execution_path(
        @namespace, @project, pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.2'
      ),
          as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: 'phac-nml/iridanextexample parameters'
      assert_select 'p', text: 'IRIDA Next Example Pipeline'

      assert_select 'label', text: 'Name (Optional)'
      assert_select 'label', text: I18n.t(:'components.nextflow.update_samples')
      assert_select 'label', text: I18n.t(:'components.nextflow.email_notification')

      assert_select 'button', I18n.t(:'workflow_executions.submissions.create.submit')

      assert_difference -> { @project.namespace.automated_workflow_executions.count }, 1 do
        post namespace_project_automated_workflow_executions_path(@namespace, @project),
             params: { workflow_execution: {
               name: 'Test Workflow',
               metadata: { pipeline_id: 'phac-nml/iridanextexample',
                           workflow_version: '1.0.2' },
               workflow_params: { assembler: 'stub' },
               email_notification: true,
               update_samples: true
             }, format: :turbo_stream }
      end

      assert_response :success
    end

    test 'can access new page without pipeline_id and workflow_version' do
      # Test line 26 else branch - when params don't have both pipeline_id and workflow_version
      get new_namespace_project_automated_workflow_execution_path(@namespace, @project), as: :turbo_stream
      assert_response :success

      # Should render the form but @workflow should be nil
      assert_select 'h1', text: I18n.t(:'projects.automated_workflow_executions.pipeline_selection_modal.title')
    end

    test 'can access new page with only pipeline_id' do
      get new_namespace_project_automated_workflow_execution_path(
        @namespace, @project, pipeline_id: 'phac-nml/iridanextexample'
      ),
          as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t(:'projects.automated_workflow_executions.pipeline_selection_modal.title')
    end

    test 'can delete an automated workflow execution for a project' do
      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      get namespace_project_automated_workflow_executions_path(@namespace, @project), as: :turbo_stream
      assert_response :success

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select "tr[id='automated_workflow_execution_#{automated_workflow_execution.id}']", count: 1
        end
      end

      assert_difference -> { @project.namespace.automated_workflow_executions.count }, -1 do
        delete namespace_project_automated_workflow_execution_path(@namespace, @project,
                                                                   automated_workflow_execution, format: :turbo_stream)
      end
      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t(
                            :'projects.automated_workflow_executions.destroy.success',
                            workflow_name: automated_workflow_execution.workflow.name
                          )}"
          end
        end
      end
    end

    test 'can edit an automated workflow execution for a project' do
      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      get edit_namespace_project_automated_workflow_execution_path(@namespace, @project,
                                                                   automated_workflow_execution, format: :turbo_stream)
      assert_response :success

      assert_select 'h1',
                    text: I18n.t(:'projects.automated_workflow_executions.edit_dialog.title',
                                 workflow_name: automated_workflow_execution.name)

      assert_changes -> { automated_workflow_execution.reload.name }, to: 'Updated AWE' do
        patch namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution),
              params: {
                workflow_execution: {
                  name: 'Updated AWE'
                },
                format: :turbo_stream
              }
      end

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select "tr[id='automated_workflow_execution_#{automated_workflow_execution.id}']", count: 1 do
            assert_select 'td:nth-child(2)', text: 'Updated AWE'
          end
        end
      end
    end

    test 'hidden edit button when automated workflow execution is disabled' do
      disabled_automated_pipeline = automated_workflow_executions(:disabled_automated_workflow_execution)
      get namespace_project_automated_workflow_executions_path(@namespace, @project), as: :turbo_stream
      assert_response :success

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select "tr[id='automated_workflow_execution_#{disabled_automated_pipeline.id}']", count: 1 do
            assert_select 'td:nth-child(7)', text: I18n.t('common.statuses.disabled').upcase
            assert_select 'td:nth-child(8)' do
              assert_select 'button', text: I18n.t('common.actions.edit'), count: 0
            end
          end
        end
      end
    end

    test 'cannot create a automated workflow execution for a project with incorrect permissions' do
      sign_in users(:ryan_doe)

      project = projects(:project2)

      post namespace_project_automated_workflow_executions_path(@namespace, project),
           params: { workflow_execution: {
             metadata: { pipeline_id: '/phac-nml/iridanextexample',
                         workflow_version: '1.0.2' },
             workflow_params: { assembler: 'stub' },
             email_notification: true,
             update_samples: true
           }, format: :turbo_stream }

      assert_response :unauthorized
    end

    test 'cannot update a automated workflow execution for a project with incorrect permissions' do
      sign_in users(:ryan_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      patch namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution),
            params: {
              workflow_execution: {
                workflow_params: { assembler: 'experimental' }
              },
              format: :turbo_stream
            }

      assert_response :unauthorized
    end

    test 'cannot destroy a automated workflow execution for a project with incorrect permissions' do
      sign_in users(:ryan_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      delete namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution,
                                                                 format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'cannot access the new page to create a automated workflow execution with incorrect permissions' do
      sign_in users(:ryan_doe)

      get new_namespace_project_automated_workflow_execution_path(@namespace, @project, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'cannot access the edit page to update a disabled automated workflow execution' do
      sign_in users(:john_doe)

      automated_workflow_execution = automated_workflow_executions(:disabled_automated_workflow_execution)

      get edit_namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution,
                                                                   params: { format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'cannot access the edit page to update an automated workflow execution with incorrect permissions' do
      sign_in users(:ryan_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      get edit_namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution,
                                                                   params: { format: :turbo_stream })

      assert_response :unauthorized
    end

    test 'can get the show page for a automated workflow execution for a project' do
      sign_in users(:john_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      get namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution)

      assert_response :success
    end

    test 'cannot access the show page for a automated workflow execution with incorrect permissions' do
      sign_in users(:ryan_doe)

      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      get namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution)

      assert_response :unauthorized

      assert_select 'h1', text: I18n.t(:'application.errors.access_denied')
    end

    test 'handles update error when workflow execution service fails' do
      sign_in users(:john_doe)
      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      # Mock the update service to return false (failure)
      mock_service = mock
      mock_service.expects(:execute).returns(false)
      AutomatedWorkflowExecutions::UpdateService.expects(:new).returns(mock_service)

      patch namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution),
            params: {
              workflow_execution: {
                name: 'Updated Name'
              },
              format: :turbo_stream
            }

      assert_response :unprocessable_content

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.error')}: #{I18n.t(
                            :'projects.automated_workflow_executions.update.error',
                            workflow_name: automated_workflow_execution.workflow.name
                          )}"
          end
        end
      end
    end

    test 'handles destroy error with proper error response' do
      automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)

      # Stub the destroy service to not actually destroy the record
      AutomatedWorkflowExecutions::DestroyService.any_instance.stubs(:execute).returns(nil)

      delete namespace_project_automated_workflow_execution_path(@namespace, @project, automated_workflow_execution,
                                                                 format: :turbo_stream)

      assert_response :unprocessable_content

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.error')}: #{I18n.t(
                            :'projects.automated_workflow_executions.destroy.error',
                            workflow_name: automated_workflow_execution.workflow.name
                          )}"
          end
        end
      end
    end

    test 'handles create error when workflow execution service fails' do
      # Mock the CreateService to return an unpersisted AutomatedWorkflowExecution
      mock_service = mock
      unpersisted_execution = AutomatedWorkflowExecution.new(
        namespace_id: @project.namespace_id,
        created_by_id: @user.id,
        name: 'Failed Execution',
        metadata: { pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params: { assembler: 'stub' }
      )
      mock_service.expects(:execute).returns(unpersisted_execution)
      AutomatedWorkflowExecutions::CreateService.expects(:new).returns(mock_service)

      post namespace_project_automated_workflow_executions_path(@namespace, @project),
           params: {
             workflow_execution: {
               name: 'Test Workflow',
               metadata: { pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
               workflow_params: { assembler: 'stub' },
               email_notification: false,
               update_samples: false
             },
             format: :turbo_stream
           }

      assert_response :unprocessable_content

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.error')}: #{I18n.t(
                            :'projects.automated_workflow_executions.create.error',
                            workflow_name: unpersisted_execution.workflow.name
                          )}"
          end
        end
      end
    end
  end
end
