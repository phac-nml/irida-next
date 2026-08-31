# frozen_string_literal: true

require 'test_helper'

module Projects
  class WorkflowExecutionsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @workflow_execution = workflow_executions(:automated_example_completed)
      @workflow_execution_running = workflow_executions(:automated_example_running)
      @namespace = groups(:group_one)
      @project = projects(:project1)
    end

    test 'should show a listing of workflow executions for the project' do
      shared_to_project = workflow_executions(:workflow_execution_shared1)
      also_shared_to_project = workflow_executions(:workflow_execution_shared2)
      not_shared_to_project = workflow_executions(:workflow_execution_shared3)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :success
      assert_select 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_select 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')
      assert_select "input[placeholder='#{I18n.t('shared.workflow_executions.index.search.placeholder')}']"
      assert_workflow_executions_table_headers
      assert_select "tr##{dom_id(shared_to_project)}", count: 1
      assert_select "tr##{dom_id(also_shared_to_project)}", count: 1
      assert_select "tr##{dom_id(not_shared_to_project)}", count: 0
      assert_select "tr##{dom_id(shared_to_project)} button", text: I18n.t('common.actions.cancel'), count: 0
      assert_select "tr##{dom_id(shared_to_project)} button", text: I18n.t('common.actions.delete'), count: 0
    end

    test 'should render bulk workflow actions based on project access level' do
      cancel_label = I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')
      delete_label = I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: cancel_label, count: 1
      assert_select 'button[role="menuitem"]', text: delete_label, count: 1

      sign_in users(:michelle_doe)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: cancel_label, count: 0
      assert_select 'button[role="menuitem"]', text: delete_label, count: 0
    end

    test 'should apply default sort and support sorting workflow executions' do
      workflow_executions(:automated_workflow_execution)
      workflow_execution2 = workflow_executions(:automated_example_canceled)
      workflow_execution3 = workflow_executions(:automated_example_canceling)
      workflow_execution4 = workflow_executions(:automated_workflow_execution_existing)
      workflow_execution_shared1 = workflow_executions(:workflow_execution_shared1)
      workflow_execution_shared2 = workflow_executions(:workflow_execution_shared2)
      workflow_execution_shared4 = workflow_executions(:workflow_execution_shared4)

      get namespace_project_workflow_executions_path(@namespace, @project)
      assert_response :success
      assert_sort_state(8, 'descending', table_selector: '#workflow-executions-table table')

      get namespace_project_workflow_executions_path(@namespace, @project), params: { q: { s: 'run_id asc' } }
      assert_response :success
      assert_sort_state(4, 'ascending', table_selector: '#workflow-executions-table table')
      assert_select '#workflow-executions-table table tbody tr:first-child td:nth-child(4)',
                    text: workflow_execution4.run_id

      get namespace_project_workflow_executions_path(@namespace, @project), params: { q: { s: 'run_id desc' } }
      assert_response :success
      assert_sort_state(4, 'descending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_execution_shared4.run_id, workflow_execution_shared2.run_id,
                                row_scope: '#workflow-executions-table table tbody')

      get namespace_project_workflow_executions_path(@namespace, @project),
          params: { q: { s: 'metadata_pipeline_id asc' } }
      assert_response :success
      assert_sort_state(5, 'ascending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_execution2.workflow.name, workflow_execution3.workflow.name,
                                row_scope: '#workflow-executions-table table tbody')

      get namespace_project_workflow_executions_path(@namespace, @project),
          params: { q: { s: 'metadata_pipeline_id desc' } }
      assert_response :success
      assert_sort_state(5, 'descending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_execution_shared1.workflow.name, workflow_execution_shared2.workflow.name,
                                row_scope: '#workflow-executions-table table tbody')
    end

    test 'should not show a listing of workflow executions for the project' do
      sign_in users(:micha_doe)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :unauthorized
    end

    test 'should not show a listing of project workflow executions for guests' do
      sign_in users(:ryan_doe)

      get namespace_project_workflow_executions_path(@namespace, @project)

      assert_response :unauthorized
    end

    test 'should apply advanced search groups' do
      get namespace_project_workflow_executions_path(@namespace, @project),
          params: workflow_advanced_search_params(state: 'completed').merge(limit: 100)

      assert_response :success
      assert_select "tr##{dom_id(@workflow_execution)}", count: 1
      assert_select "tr##{dom_id(@workflow_execution_running)}", count: 0
    end

    test 'should show workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :success
      w3c_validate 'Project Workflow Execution Show Page'
    end

    test 'should show shared workflow execution with action restrictions and tab content' do
      workflow_execution = workflow_executions(:workflow_execution_shared2)
      output_attachment = attachments(:workflow_execution_shared_with_project_output_attachment)
      cancel_action = cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)
      edit_action = edit_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)
      destroy_action =
        destroy_confirmation_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :success
      w3c_validate 'Project Workflow Execution Show Page'
      assert_select "form[action^='#{new_data_export_path}']", count: 1
      assert_select "form[action='#{cancel_action}']", count: 0
      assert_select "form[action='#{edit_action}']", count: 0
      assert_select "form[action='#{destroy_action}']", count: 0

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution), params: { tab: 'files' }

      assert_response :success
      assert_select '#files-panel-content tbody', text: /#{output_attachment.puid}/
      assert_select '#files-panel-content tbody', text: /#{output_attachment.file.filename}/

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution), params: { tab: 'params' }

      assert_response :success
      assert_select '#workflow-executions-tabs'
    end

    test 'should not show shared workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)
      workflow_execution = workflow_executions(:workflow_execution_shared1)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show workflow execution that is not shared' do
      workflow_execution = workflow_executions(:workflow_execution_valid)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :not_found
    end

    test 'should not show workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show project workflow execution for guests' do
      sign_in users(:ryan_doe)
      workflow_execution = workflow_executions(:automated_workflow_execution)

      get namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_response :unauthorized
    end

    test 'should apply project workflow cancellation state transitions' do
      scenarios = [
        { fixture: :automated_example_new, from_state: :initial, expected_state: 'canceled' },
        { fixture: :automated_example_prepared, from_state: :prepared, expected_state: 'canceled' },
        { fixture: :automated_example_submitted, from_state: :submitted, expected_state: 'canceling' },
        { fixture: :automated_example_running, from_state: :running, expected_state: 'canceling' },
        { fixture: :automated_example_completed, from_state: :completed, response: :unprocessable_content }
      ]

      assert_cancel_state_transitions(
        cancel_path: lambda { |workflow_execution|
          cancel_namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)
        },
        scenarios:
      )
    end

    test 'should apply project workflow deletion state transitions' do
      scenarios = [
        {
          fixture: :automated_example_prepared,
          from_state: :prepared,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :automated_example_submitted,
          from_state: :submitted,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :automated_example_completed,
          from_state: :completed,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { namespace_project_workflow_executions_path(@namespace, @project) }
        },
        {
          fixture: :automated_example_error,
          from_state: :error,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { namespace_project_workflow_executions_path(@namespace, @project) }
        },
        {
          fixture: :automated_example_canceling,
          from_state: :canceling,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :automated_example_canceled,
          from_state: :canceled,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { namespace_project_workflow_executions_path(@namespace, @project) }
        },
        {
          fixture: :automated_example_running,
          from_state: :running,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :automated_example_new,
          from_state: :initial,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        }
      ]

      assert_destroy_state_transitions(
        destroy_path: lambda { |workflow_execution|
          namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)
        },
        scenarios:
      )
    end

    test 'redirect to project workflow executions page when workflow execution is deleted' do
      workflow_execution = workflow_executions(:automated_example_canceled)

      delete namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, redirect: true),
             as: :turbo_stream
      assert_response :redirect

      assert_redirected_to namespace_project_workflow_executions_path(@namespace, @project)
    end

    test 'analyst or higher access level can update workflow execution name post launch' do
      new_name = 'New Name'
      update_params = { workflow_execution: { name: new_name } }

      put namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution),
          params: update_params, as: :turbo_stream

      assert_response :success
      assert_equal new_name, @workflow_execution.reload.name
      assert_turbo_stream_flash(
        I18n.t('concerns.workflow_execution_actions.update.success',
               workflow_name: @workflow_execution.workflow.name)
      )
      assert_select 'turbo-stream[action="replace"][target="workflow_execution_summary"]'
    end

    test 'access level less than analyst cannot update workflow execution name post launch for an automated workflow' do
      sign_in users(:ryan_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution),
          params: update_params, as: :turbo_stream

      assert_response :unauthorized
    end

    test 'should open destroy_confirmation' do
      get destroy_confirmation_namespace_project_workflow_execution_path(
        @namespace, @project, @workflow_execution, format: :turbo_stream
      )

      assert_response :success
      assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
        assert_select 'h1', I18n.t('shared.workflow_executions.destroy_confirmation_dialog.title')
      end
    end

    test 'should open cancel_multiple_confirmation' do
      get cancel_multiple_confirmation_namespace_project_workflow_executions_path(
        @namespace, @project, format: :turbo_stream
      )

      assert_response :success
      assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
        assert_select 'h1', I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.title')
      end
    end

    test 'should open destroy_multiple_confirmation' do
      get destroy_multiple_confirmation_namespace_project_workflow_executions_path(
        @namespace, @project, format: :turbo_stream
      )

      assert_response :success
      assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
        assert_select 'h1', I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.title')
      end
    end

    test 'should not open destroy_multiple_confirmation due to unauthorized access' do
      sign_in users(:ryan_doe)
      get destroy_multiple_confirmation_namespace_project_workflow_executions_path(
        @namespace, @project, format: :turbo_stream
      )

      assert_response :unauthorized
    end

    test 'should destroy multiple workflows at once' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2 do
                          post destroy_multiple_namespace_project_workflow_executions_path(
                            @namespace,
                            @project
                          ), params: { destroy_multiple:
                                          { workflow_execution_ids: [error_workflow.id, canceled_workflow.id],
                                            namespace: @namespace } },
                             as: :turbo_stream
                        end
      assert_response :success
      assert_turbo_stream_flash(I18n.t('concerns.workflow_execution_actions.destroy_multiple.success'))
      assert_select 'turbo-stream[action="refresh"]'
    end

    test 'should partially destroy multiple workflows at once' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)
      running_workflow = workflow_executions(:automated_example_running)

      assert_difference -> { WorkflowExecution.count } => -2,
                        -> { SamplesWorkflowExecution.count } => -2 do
                          post destroy_multiple_namespace_project_workflow_executions_path(
                            @namespace,
                            @project
                          ), params: {
                            destroy_multiple: {
                              workflow_execution_ids: [error_workflow.id, canceled_workflow.id,
                                                       running_workflow.id], namespace: @namespace
                            }
                          }, as: :turbo_stream
                        end
      assert_response :multi_status
    end

    test 'should not destroy multiple non-deletable workflows' do
      running_workflow = workflow_executions(:automated_example_running)
      new_workflow = workflow_executions(:automated_example_new)
      assert_no_difference [-> { WorkflowExecution.count }, -> { SamplesWorkflowExecution.count }] do
        post destroy_multiple_namespace_project_workflow_executions_path(
          @namespace,
          @project
        ), params: {
          destroy_multiple: { workflow_execution_ids: [running_workflow.id, new_workflow.id], namespace: @namespace }
        }, as: :turbo_stream
      end
      assert_response :unprocessable_content
    end

    test 'should not destroy workflows if unauthorized' do
      sign_in users(:ryan_doe)
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)

      assert_no_difference [-> { WorkflowExecution.count }, -> { SamplesWorkflowExecution.count }] do
        post destroy_multiple_namespace_project_workflow_executions_path(
          @namespace,
          @project
        ), params: {
          destroy_multiple: { workflow_execution_ids: [canceled_workflow.id, error_workflow.id] }
        }, as: :turbo_stream
      end
      assert_response :unauthorized
    end

    test 'should cancel multiple workflows at once' do
      running_workflow = workflow_executions(:automated_example_running)
      new_workflow = workflow_executions(:automated_example_new)
      post cancel_multiple_namespace_project_workflow_executions_path(
        @namespace,
        @project
      ), params: { cancel_multiple:
                      { workflow_execution_ids: [running_workflow.id, new_workflow.id],
                        namespace: @namespace } },
         as: :turbo_stream

      assert_response :success
      assert_turbo_stream_flash(I18n.t('concerns.workflow_execution_actions.cancel_multiple.success'))
      assert_select 'turbo-stream[action="refresh"]'
    end

    test 'should partially cancel multiple workflows at once' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)
      running_workflow = workflow_executions(:automated_example_running)

      post cancel_multiple_namespace_project_workflow_executions_path(
        @namespace,
        @project
      ), params: {
        cancel_multiple: {
          workflow_execution_ids: [error_workflow.id, canceled_workflow.id,
                                   running_workflow.id], namespace: @namespace
        }
      }, as: :turbo_stream
      assert_response :multi_status
    end

    test 'should not cancel multiple un-cancellable workflows' do
      canceled_workflow = workflow_executions(:automated_example_canceled)
      error_workflow = workflow_executions(:automated_example_error)
      post cancel_multiple_namespace_project_workflow_executions_path(
        @namespace,
        @project
      ), params: {
        cancel_multiple: { workflow_execution_ids: [canceled_workflow.id, error_workflow.id], namespace: @namespace }
      }, as: :turbo_stream
      assert_response :unprocessable_content
    end

    test 'should not cancel workflows if unauthorized' do
      sign_in users(:michelle_doe)
      running_workflow = workflow_executions(:automated_example_running)
      new_workflow = workflow_executions(:automated_example_new)

      post cancel_multiple_namespace_project_workflow_executions_path(
        @namespace,
        @project
      ), params: {
        cancel_multiple: { workflow_execution_ids: [running_workflow.id, new_workflow.id] }
      }, as: :turbo_stream
      assert_response :unauthorized
    end

    test 'should not cancel shared workflow' do
      running_workflow = workflow_executions(:automated_example_running)
      shared_workflow = workflow_executions(:workflow_execution_shared4)

      post cancel_multiple_namespace_project_workflow_executions_path(
        @namespace,
        @project
      ), params: {
        cancel_multiple: { workflow_execution_ids: [running_workflow.id, shared_workflow.id] }
      }, as: :turbo_stream
      assert_response :multi_status
    end

    test 'accessing workflow executions index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_workflow_executions_path(@namespace, @project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
