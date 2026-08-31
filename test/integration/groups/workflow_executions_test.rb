# frozen_string_literal: true

require 'test_helper'

module Groups
  class WorkflowExecutionsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:joan_doe)
      @group = groups(:group_one)
      @workflow_execution = workflow_executions(:workflow_execution_group_shared1)
      @workflow_execution_completed = workflow_executions(:workflow_execution_group_shared_completed)
      @workflow_execution_running = workflow_executions(:workflow_execution_group_shared_running)
    end

    test 'should show a listing of workflow executions for the group' do
      group_shared_workflow = workflow_executions(:workflow_execution_group_shared1)
      project_shared_workflow = workflow_executions(:workflow_execution_shared1)

      get group_workflow_executions_path(@group)

      assert_response :success
      assert_select 'p', text: I18n.t(:'groups.workflow_executions.index.subtitle', locale: users(:joan_doe).locale)
      assert_select "input[placeholder='#{I18n.t('shared.workflow_executions.index.search.placeholder',
                                                 locale: users(:joan_doe).locale)}']"
      assert_workflow_executions_table_headers(locale: users(:joan_doe).locale)
      assert_select "tr##{dom_id(group_shared_workflow)}", count: 1
      assert_select "tr##{dom_id(project_shared_workflow)}", count: 0
      assert_select '#workflow-executions-table table tbody button', text: I18n.t('common.actions.cancel'), count: 0
      assert_select '#workflow-executions-table table tbody button', text: I18n.t('common.actions.delete'), count: 0
    end

    test 'should apply default sort and support sorting workflow executions' do
      workflow_execution_running = workflow_executions(:workflow_execution_group_shared_running)
      workflow_execution_prepared = workflow_executions(:workflow_execution_group_shared_prepared)
      workflow_execution_submitted = workflow_executions(:workflow_execution_group_shared_submitted)
      workflow_execution_shared2 = workflow_executions(:workflow_execution_group_shared2)
      get group_workflow_executions_path(@group)
      assert_response :success
      assert_sort_state(8, 'descending', table_selector: '#workflow-executions-table table')

      get group_workflow_executions_path(@group), params: { q: { s: 'run_id asc' } }
      assert_response :success
      assert_sort_state(4, 'ascending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_execution_running.run_id, workflow_execution_prepared.run_id,
                                row_scope: '#workflow-executions-table table tbody')

      get group_workflow_executions_path(@group), params: { q: { s: 'run_id desc' } }
      assert_response :success
      assert_sort_state(4, 'descending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_executions(:workflow_execution_group_shared3).run_id,
                                workflow_execution_shared2.run_id,
                                row_scope: '#workflow-executions-table table tbody')

      get group_workflow_executions_path(@group), params: { q: { s: 'metadata_pipeline_id asc' } }
      assert_response :success
      assert_sort_state(5, 'ascending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(@workflow_execution.workflow.name, workflow_execution_shared2.workflow.name,
                                row_scope: '#workflow-executions-table table tbody')

      get group_workflow_executions_path(@group), params: { q: { s: 'metadata_pipeline_id desc' } }
      assert_response :success
      assert_sort_state(5, 'descending', table_selector: '#workflow-executions-table table')
      assert_first_rows_include(workflow_execution_running.workflow.name, workflow_execution_submitted.workflow.name,
                                row_scope: '#workflow-executions-table table tbody')
    end

    test 'should not show a listing of workflow executions for the group' do
      sign_in users(:micha_doe)

      get group_workflow_executions_path(@group)

      assert_response :unauthorized
    end

    test 'should not show a listing of group workflow executions for guests' do
      sign_in users(:ryan_doe)

      get group_workflow_executions_path(@group)

      assert_response :unauthorized
    end

    test 'should apply advanced search groups' do
      get group_workflow_executions_path(@group),
          params: workflow_advanced_search_params(state: 'completed').merge(limit: 100)

      assert_response :success
      assert_select "tr##{dom_id(@workflow_execution_completed)}", count: 1
      assert_select "tr##{dom_id(@workflow_execution_running)}", count: 0
    end

    test 'should show workflow execution that was shared to group by the user' do
      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :success
    end

    test 'should show shared-by-other-user group workflow with action restrictions and tab content' do
      workflow_execution = workflow_executions(:workflow_execution_group_shared2)
      locale = users(:joan_doe).locale

      get group_workflow_execution_path(@group, workflow_execution)

      assert_response :success
      assert_select "form[action^='#{new_data_export_path}']", count: 1
      assert_select "form[action='#{cancel_group_workflow_execution_path(@group, workflow_execution)}']", count: 0
      assert_select "form[action='#{edit_group_workflow_execution_path(@group, workflow_execution)}']", count: 0

      get group_workflow_execution_path(@group, workflow_execution), params: { tab: 'files' }

      assert_response :success
      assert_select '#files-panel-content',
                    text: /#{Regexp.escape(I18n.t('workflow_executions.files.empty.title', locale: locale))}/
      assert_select '#files-panel-content',
                    text: /#{Regexp.escape(I18n.t('workflow_executions.files.empty.description', locale: locale))}/

      get group_workflow_execution_path(@group, workflow_execution), params: { tab: 'params' }

      assert_response :success
      assert_select 'div.project_name-param span', text: '--project_name'
      assert_select 'div.assembler-param span', text: '--assembler'

      deletable_workflow_execution = workflow_executions(:workflow_execution_group_shared_completed)

      get group_workflow_execution_path(@group, deletable_workflow_execution)

      assert_response :success
      assert_select 'button', text: I18n.t('common.actions.remove', locale: locale), count: 0
    end

    test 'should not show shared workflow execution for user with incorrect permissions' do
      sign_in users(:micha_doe)

      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :unauthorized
    end

    test 'should not show workflow execution that is not shared' do
      workflow_execution = workflow_executions(:workflow_execution_valid)

      get group_workflow_execution_path(@group, workflow_execution)

      assert_response :not_found
    end

    test 'should not show group workflow execution for guests' do
      sign_in users(:ryan_doe)

      get group_workflow_execution_path(@group, @workflow_execution)

      assert_response :unauthorized
    end

    test 'should not cancel a workflow if user is not the submitter ' do
      workflow_execution = workflow_executions(:workflow_execution_group_shared_new)

      put cancel_group_workflow_execution_path(@group, workflow_execution), as: :turbo_stream

      assert_response :unauthorized
    end

    test 'should apply group workflow cancellation state transitions' do
      submitter = users(:james_doe)
      sign_in submitter

      scenarios = [
        { fixture: :workflow_execution_group_shared_new, from_state: :initial, expected_state: 'canceled' },
        { fixture: :workflow_execution_group_shared_prepared, from_state: :prepared, expected_state: 'canceled' },
        {
          fixture: :workflow_execution_group_shared_submitted,
          from_state: :submitted,
          expected_state: 'canceling'
        },
        { fixture: :workflow_execution_group_shared_running, from_state: :running, expected_state: 'canceling' },
        {
          fixture: :workflow_execution_group_shared_completed,
          from_state: :completed,
          response: :unprocessable_content
        }
      ]

      assert_cancel_state_transitions(
        cancel_path: ->(workflow_execution) { cancel_group_workflow_execution_path(@group, workflow_execution) },
        scenarios:,
        locale: submitter.locale
      )
    end

    test 'submitter should be able to update their shared workflow executions name post launch' do
      new_name = 'New Name'
      update_params = { workflow_execution: { name: new_name } }

      put group_workflow_execution_path(@group, @workflow_execution),
          params: update_params, as: :turbo_stream

      assert_response :success
      assert_equal new_name, @workflow_execution.reload.name
      assert_turbo_stream_flash(
        I18n.t('concerns.workflow_execution_actions.update.success',
               workflow_name: @workflow_execution.workflow.name,
               locale: users(:joan_doe).locale),
        locale: users(:joan_doe).locale
      )
      assert_select 'turbo-stream[action="replace"][target="workflow_execution_summary"]'
    end

    test 'non-submitter group member should not be able to update a shared workflow executions name post launch' do
      sign_in users(:james_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put group_workflow_execution_path(@group, @workflow_execution),
          params: update_params, as: :turbo_stream

      assert_response :unauthorized
    end

    test 'non-submitter non group member should not be able to update a shared workflow executions name post launch' do
      sign_in users(:micha_doe)

      update_params = { workflow_execution: { name: 'New Name' } }

      put group_workflow_execution_path(@group, @workflow_execution),
          params: update_params, as: :turbo_stream

      assert_response :unauthorized
    end

    test 'should apply group workflow deletion state transitions' do
      sign_in users(:james_doe)

      scenarios = [
        {
          fixture: :workflow_execution_group_shared_prepared,
          from_state: :prepared,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :workflow_execution_group_shared_submitted,
          from_state: :submitted,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :workflow_execution_group_shared_completed,
          from_state: :completed,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { group_workflow_executions_path(@group) }
        },
        {
          fixture: :workflow_execution_group_shared_error,
          from_state: :error,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { group_workflow_executions_path(@group) }
        },
        {
          fixture: :workflow_execution_group_shared_canceling,
          from_state: :canceling,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :workflow_execution_group_shared_canceled,
          from_state: :canceled,
          workflow_count_delta: -1,
          samples_count_delta: -1,
          response: :redirect,
          redirect_to: -> { group_workflow_executions_path(@group) }
        },
        {
          fixture: :workflow_execution_group_shared_running,
          from_state: :running,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        },
        {
          fixture: :workflow_execution_group_shared_new,
          from_state: :initial,
          workflow_count_delta: 0,
          samples_count_delta: 0,
          response: :unprocessable_content
        }
      ]

      assert_destroy_state_transitions(
        destroy_path: ->(workflow_execution) { group_workflow_execution_path(@group, workflow_execution) },
        scenarios:
      )
    end

    test 'redirect to project workflow executions page when workflow execution is deleted' do
      sign_in users(:james_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared_canceled)

      delete group_workflow_execution_path(@group, workflow_execution, redirect: true), as: :turbo_stream
      assert_response :redirect

      assert_redirected_to group_workflow_executions_path(@group)
    end

    test 'accessing workflow executions index on invalid page causes pagy overflow redirect at group level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get group_workflow_executions_path(@group, page: 50)

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
