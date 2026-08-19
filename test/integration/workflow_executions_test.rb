# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:john_doe)
    @sample1 = samples(:sample1)
    @attachment1 = attachments(:attachment1)
    @workflow_execution_completed = workflow_executions(:irida_next_example_completed)
    @workflow_execution_error = workflow_executions(:irida_next_example_error)
    @workflow_execution_canceled = workflow_executions(:irida_next_example_canceled)
    @workflow_execution_running = workflow_executions(:irida_next_example_running)
    @workflow_execution_new = workflow_executions(:irida_next_example_new)
  end

  test 'should render global workflow execution listing content and server-side row visibility' do
    shared_workflow = workflow_executions(:workflow_execution_shared1)
    other_users_shared_workflow = workflow_executions(:workflow_execution_shared2)

    get workflow_executions_path

    assert_response :success
    assert_select 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
    assert_select "input[placeholder='#{I18n.t('shared.workflow_executions.index.search.placeholder')}']"
    assert_workflow_executions_table_headers

    assert_select "tr##{dom_id(shared_workflow)}", count: 1
    assert_select "tr##{dom_id(other_users_shared_workflow)}", count: 0

    prepared_workflow = workflow_executions(:irida_next_example_prepared)
    completed_workflow = workflow_executions(:irida_next_example_completed)

    assert_select "tr##{dom_id(prepared_workflow)} button", text: I18n.t('common.actions.cancel'), count: 1
    assert_select "tr##{dom_id(prepared_workflow)} button", text: I18n.t('common.actions.delete'), count: 0
    assert_select "tr##{dom_id(completed_workflow)} button", text: I18n.t('common.actions.delete'), count: 1
    assert_select "tr##{dom_id(shared_workflow)} button",
                  text: I18n.t('common.actions.cancel'), count: 1
  end

  test 'should filter global workflow execution listing by id or name' do
    workflow_execution = workflow_executions(:workflow_execution_existing)
    other_workflow_execution = workflow_executions(:workflow_execution_valid)

    get workflow_executions_path, params: { q: { name_or_id_cont: workflow_execution.id } }

    assert_response :success
    assert_select "tr##{dom_id(workflow_execution)}", count: 1
    assert_select "tr##{dom_id(other_workflow_execution)}", count: 0

    get workflow_executions_path, params: { q: { name_or_id_cont: other_workflow_execution.name } }

    assert_response :success
    assert_select "tr##{dom_id(other_workflow_execution)}", count: 1
    assert_select "tr##{dom_id(workflow_execution)}", count: 0
  end

  test 'should render quick search results messages for zero and multiple matches' do
    search_term = 'irida_next_example'
    get workflow_executions_path, params: { q: { name_or_id_cont: search_term }, limit: 100 }

    assert_response :success
    assert_select '[role=status]', text: /results found for '#{search_term}'/

    missing_term = 'zzz-no-such-workflow'
    get workflow_executions_path, params: { q: { name_or_id_cont: missing_term } }

    assert_response :success
    assert_select '[role=status]', text: I18n.t('components.search.results_message.zero', search_term: missing_term)
  end

  test 'should paginate global workflow executions' do
    get workflow_executions_path, params: { page: 2 }

    assert_response :success
    assert_select '#workflow-executions-table table tbody tr', count: 2
    assert_select '#prev-page-link', count: 1
    assert_select '#next-page-link', count: 0
  end

  test 'should create workflow execution with valid params' do
    assert_difference -> { WorkflowExecution.count } => 1,
                      -> { SamplesWorkflowExecution.count } => 1 do
      post workflow_executions_path, as: :turbo_stream,
                                     params: {
                                       workflow_execution: {
                                         metadata: {
                                           pipeline_id: 'phac-nml/iridanextexample',
                                           workflow_version: '1.0.2'
                                         },
                                         workflow_params: { assembler: 'stub' },
                                         workflow_type: 'NFL',
                                         workflow_type_version: 'DSL2',
                                         workflow_engine: 'nextflow',
                                         workflow_engine_version: '24.10.3',
                                         workflow_engine_parameters: { '-r': 'dev' },
                                         workflow_url: 'https://github.com/phac-nml/iridanextexample',
                                         email_notification: true,
                                         shared_with_namespace: true,
                                         namespace_id: projects(:project1).namespace.id,
                                         samples_workflow_executions_attributes: [
                                           {
                                             sample_id: @sample1.id,
                                             samplesheet_params: {
                                               sample: @sample1.puid,
                                               'fastq_1' => @attachment1.to_global_id,
                                               'fastq_2' => ''
                                             }
                                           }
                                         ],
                                         name: 'Newest Workflow Execution'
                                       }
                                     }

      assert_response :redirect
    end

    created_workflow_execution = WorkflowExecution.last

    assert_equal users(:john_doe), created_workflow_execution.submitter

    assert_equal 1, created_workflow_execution.samples_workflow_executions.count
    assert_equal @sample1, created_workflow_execution.samples_workflow_executions.first.sample
    assert_equal true, created_workflow_execution.email_notification
    assert_equal true, created_workflow_execution.shared_with_namespace
  end

  test 'should render an error dialog when workflow execution create fails' do
    assert_no_difference -> { WorkflowExecution.count } do
      post workflow_executions_path, as: :turbo_stream,
                                     params: {
                                       workflow_execution: {
                                         metadata: {
                                           pipeline_id: 'phac-nml/iridanextexample',
                                           workflow_version: '1.0.2'
                                         },
                                         namespace_id: projects(:project1).namespace.id,
                                         samples_workflow_executions_attributes: [
                                           { sample_id: @sample1.id, samplesheet_params: { sample: @sample1.puid } }
                                         ],
                                         name: ''
                                       }
                                     }
    end

    assert_response :unprocessable_content
    assert_select '#workflow_execution_error_dialog'
  end

  test 'should select and deselect workflow executions' do
    get select_workflow_executions_path

    assert_response :success
    assert_select '[data-table-selection-ids-value="[]"]'

    get select_workflow_executions_path, params: { select: 'on' }

    assert_response :success
    assert_select '[data-table-selection-ids-value="[]"]', count: 0
    assert_includes css_select('[data-table-selection-ids-value]').first['data-table-selection-ids-value'],
                    @workflow_execution_completed.id.to_s
  end

  test 'should apply advanced search groups' do
    get workflow_executions_path, params: workflow_advanced_search_params(state: 'completed').merge(limit: 100)

    assert_response :success
    assert_select "tr##{dom_id(@workflow_execution_completed)}", count: 1
    assert_select "tr##{dom_id(@workflow_execution_running)}", count: 0
  end

  test 'should apply advanced search groups when workflow advanced-search uses translated state labels' do
    get workflow_executions_path,
        params: workflow_advanced_search_params(state: I18n.t('workflow_executions.state.completed')).merge(limit: 100)

    assert_response :success
    assert_select "tr##{dom_id(@workflow_execution_completed)}", count: 1
    assert_select "tr##{dom_id(@workflow_execution_running)}", count: 0
  end

  test 'should apply advanced search not_in state arrays when blank values are submitted' do
    get workflow_executions_path,
        params: workflow_advanced_search_params(
          operator: 'not_in',
          state: ['', 'initial', 'prepared', 'submitted', 'running', 'completing', 'error', 'canceling', 'canceled']
        ).merge(limit: 100)

    assert_response :success
    assert_select "tr##{dom_id(@workflow_execution_completed)}", count: 1
    assert_select "tr##{dom_id(@workflow_execution_running)}", count: 0
    assert_select "tr##{dom_id(@workflow_execution_new)}", count: 0
  end

  test 'should render advanced search zero results message' do
    get workflow_executions_path,
        params: {
          q: {
            groups_attributes: {
              '0' => {
                conditions_attributes: {
                  '0' => { field: 'name', operator: 'contains', value: 'zzz-no-such-workflow' }
                }
              }
            }
          }
        }

    assert_response :success
    assert_select '[role=status]', text: I18n.t('components.search.advanced.results_message.zero')
  end

  test 'should render advanced search singular results message' do
    get workflow_executions_path,
        params: {
          q: {
            groups_attributes: {
              '0' => {
                conditions_attributes: {
                  '0' => { field: 'name', operator: '=', value: @workflow_execution_completed.name }
                }
              }
            }
          }
        }

    assert_response :success
    assert_select '[role=status]', text: I18n.t('components.search.advanced.results_message.singular')
  end

  test 'should apply default sort and support sorting workflow executions' do
    workflow_execution = workflow_executions(:irida_next_example)
    workflow_execution_shared1 = workflow_executions(:workflow_execution_shared1)
    workflow_execution_metadata_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    workflow_execution_metadata_dates2 = workflow_executions(:workflow_execution_with_metadata_dates2)

    get workflow_executions_path
    assert_response :success
    assert_sort_state(8, 'descending', table_selector: '#workflow-executions-table table')

    get workflow_executions_path, params: { q: { s: 'run_id asc' } }
    assert_response :success
    assert_sort_state(4, 'ascending', table_selector: '#workflow-executions-table table')
    assert_select '#workflow-executions-table table tbody tr:first-child td:nth-child(4)',
                  text: workflow_execution_metadata_dates.run_id

    get workflow_executions_path, params: { q: { s: 'run_id desc' } }
    assert_response :success
    assert_sort_state(4, 'descending', table_selector: '#workflow-executions-table table')
    assert_select '#workflow-executions-table table tbody tr:first-child td:nth-child(4)',
                  text: workflow_execution.run_id

    get workflow_executions_path, params: { q: { s: 'metadata_pipeline_id asc' } }
    assert_response :success
    assert_sort_state(5, 'ascending', table_selector: '#workflow-executions-table table')
    assert_select '#workflow-executions-table table tbody tr:first-child td:nth-child(5)',
                  text: workflow_execution_metadata_dates2.workflow.name

    get workflow_executions_path, params: { q: { s: 'metadata_pipeline_id desc' } }
    assert_response :success
    assert_sort_state(5, 'descending', table_selector: '#workflow-executions-table table')
    assert_select '#workflow-executions-table table tbody tr:first-child td:nth-child(5)',
                  text: workflow_execution_shared1.workflow.name
  end

  test 'should cancel a new workflow with valid params' do
    put cancel_workflow_execution_path(@workflow_execution_new), as: :turbo_stream
    # A new workflow goes directly to the canceled state as ga4gh does not know it exists
    assert_workflow_execution_cancel_success(@workflow_execution_new, expected_state: 'canceled')
  end

  test 'should cancel a prepared workflow with valid params' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    put cancel_workflow_execution_path(workflow_execution), as: :turbo_stream
    # A prepared workflow goes directly to the canceled state as ga4gh does not know it exists
    assert_workflow_execution_cancel_success(workflow_execution, expected_state: 'canceled')
  end

  test 'should not delete a prepared workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)
    assert workflow_execution.prepared?
    assert_difference -> { WorkflowExecution.count } => 0,
                      -> { SamplesWorkflowExecution.count } => 0 do
      delete workflow_execution_path(workflow_execution), as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should cancel a submitted workflow with valid params' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)
    assert workflow_execution.submitted?

    put cancel_workflow_execution_path(workflow_execution), as: :turbo_stream
    # A submitted workflow goes to the canceling state as ga4gh must be sent a cancel request
    assert_workflow_execution_cancel_success(workflow_execution, expected_state: 'canceling')
  end

  test 'should not delete a submitted workflow' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)
    assert workflow_execution.submitted?
    assert_difference -> { WorkflowExecution.count } => 0,
                      -> { SamplesWorkflowExecution.count } => 0 do
      delete workflow_execution_path(workflow_execution), as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should not cancel a completed workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed)
    assert workflow_execution.completed?

    put cancel_workflow_execution_path(workflow_execution), as: :turbo_stream
    assert_response :unprocessable_content

    assert workflow_execution.completed?
  end

  test 'should delete a completed workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed)
    assert workflow_execution.completed?
    assert_difference -> { WorkflowExecution.count } => -1,
                      -> { SamplesWorkflowExecution.count } => -1 do
      delete workflow_execution_path(workflow_execution), as: :turbo_stream
    end
    assert_response :redirect
    assert_redirected_to workflow_executions_path
  end

  test 'should delete an errored workflow' do
    assert @workflow_execution_error.error?
    assert_difference -> { WorkflowExecution.count } => -1,
                      -> { SamplesWorkflowExecution.count } => -1 do
      delete workflow_execution_path(@workflow_execution_error), as: :turbo_stream
    end
    assert_response :redirect
    assert_redirected_to workflow_executions_path
  end

  test 'should not delete a canceling workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceling)
    assert workflow_execution.canceling?
    assert_difference -> { WorkflowExecution.count } => 0,
                      -> { SamplesWorkflowExecution.count } => 0 do
      delete workflow_execution_path(workflow_execution), as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should delete a canceled workflow' do
    assert @workflow_execution_canceled.canceled?
    assert_difference -> { WorkflowExecution.count } => -1,
                      -> { SamplesWorkflowExecution.count } => -1 do
      delete workflow_execution_path(@workflow_execution_canceled), as: :turbo_stream
    end
    assert_response :redirect
    assert_redirected_to workflow_executions_path
  end

  test 'should not delete a running workflow' do
    assert @workflow_execution_running.running?
    assert_difference -> { WorkflowExecution.count } => 0,
                      -> { SamplesWorkflowExecution.count } => 0 do
      delete workflow_execution_path(@workflow_execution_running), as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should cancel a running workflow' do
    assert @workflow_execution_running.running?

    put cancel_workflow_execution_path(@workflow_execution_running), as: :turbo_stream
    # A running workflow goes to the canceling state as ga4gh must be sent a cancel request
    assert_workflow_execution_cancel_success(@workflow_execution_running, expected_state: 'canceling')
  end

  test 'should not delete a new workflow' do
    assert @workflow_execution_new.initial?
    assert_difference -> { WorkflowExecution.count } => 0,
                      -> { SamplesWorkflowExecution.count } => 0 do
      delete workflow_execution_path(@workflow_execution_new), as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should show workflow execution with summary and tab content' do
    workflow_execution = workflow_executions(:workflow_execution_existing)
    sample = samples(:sample1)
    attachment = attachments(:attachment1)

    get workflow_execution_path(workflow_execution)

    assert_response :success
    assert_select '#workflow-executions-tabs'
    assert_select 'dt', text: I18n.t('workflow_executions.summary.workflow_name')
    assert_select 'dd', text: workflow_execution.workflow.name
    assert_select 'a', text: workflow_execution.namespace.name

    get workflow_execution_path(workflow_execution), params: { tab: 'params' }

    assert_response :success
    assert_select 'div.project_name-param span', text: '--project_name'
    assert_select 'div.project_name-param input[value="assembly"]'
    assert_select 'div.assembler-param span', text: '--assembler'
    assert_select 'div.assembler-param input[value="stub"]'
    assert_select 'div.random_seed-param span', text: '--random_seed'
    assert_select 'div.random_seed-param input[value="1"]'

    get workflow_execution_path(@workflow_execution_completed), params: { tab: 'samplesheet' }

    assert_response :success
    assert_select 'table tbody tr', count: 1
    assert_select 'table tbody', text: /#{sample.puid}/
    assert_select 'table tbody', text: /#{attachment.puid}/

    get workflow_execution_path(workflow_execution), params: { tab: 'files' }

    assert_response :success
    assert_select '#files-panel-content', text: /#{Regexp.escape(I18n.t('workflow_executions.files.empty.title'))}/
    assert_select '#files-panel-content',
                  text: /#{Regexp.escape(I18n.t('workflow_executions.files.empty.description'))}/
  end

  test 'should filter files tab attachments with server-side query params' do
    workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
    matching_attachment = attachments(:samples_workflow_execution_completed_output_attachment)
    non_matching_attachment = attachments(:workflow_execution_completed_output_attachment)

    get workflow_execution_path(workflow_execution),
        params: {
          tab: 'files',
          q: {
            puid_or_file_blob_filename_cont: matching_attachment.puid
          }
        }

    assert_response :success
    assert_select '#files-panel-content tbody', text: /#{matching_attachment.puid}/
    assert_select '#files-panel-content tbody', text: /#{non_matching_attachment.puid}/, count: 0

    get workflow_execution_path(workflow_execution),
        params: {
          tab: 'files',
          q: {
            puid_or_file_blob_filename_cont: non_matching_attachment.file.filename.to_s
          }
        }

    assert_response :success
    assert_select '#files-panel-content tbody', text: /#{matching_attachment.puid}/, count: 0
    assert_select '#files-panel-content tbody', text: /#{non_matching_attachment.puid}/
  end

  test 'should apply files tab page size through query params' do
    workflow_execution = workflow_executions(:irida_next_example_completed_with_output)

    get workflow_execution_path(workflow_execution), params: { tab: 'files', limit: 10 }

    assert_response :success
    assert_select '#files-panel-content tbody tr', count: 2
    assert_select '#files-panel-content a[href*="limit=10"][href*="tab=files"]'
    assert_select '#files-panel-content #pagy-limit-select option[value="10"][selected]'
  end

  test 'should render shared workflow actions for submitter in global show page' do
    workflow_execution = workflow_executions(:workflow_execution_shared1)

    get workflow_execution_path(workflow_execution)

    assert_response :success

    assert_select "form[action^='#{new_data_export_path}']", count: 1
    assert_select "form[action='#{cancel_workflow_execution_path(workflow_execution)}']", count: 1
    assert_select "form[action='#{edit_workflow_execution_path(workflow_execution)}']", count: 1
    assert_select "form[action='#{destroy_confirmation_workflow_execution_path(workflow_execution)}']", count: 0
  end

  test 'should show deleted namespace badge when workflow namespace project is deleted' do
    workflow_execution = workflow_executions(:workflow_execution_existing)
    project = workflow_execution.namespace.project

    Projects::DestroyService.new(project, users(:john_doe)).execute

    get workflow_execution_path(workflow_execution)

    assert_response :success
    assert_includes response.body, workflow_execution.namespace.name
    assert_includes response.body, I18n.t('workflow_executions.summary.deleted')
    assert_select 'a', text: workflow_execution.namespace.name, count: 0
  end

  test 'should show workflow stdout and stderr links when attached' do
    @workflow_execution_completed.stdout.attach(
      io: StringIO.new('workflow stdout logs'),
      filename: 'stdout.txt',
      content_type: 'text/plain'
    )
    @workflow_execution_completed.stderr.attach(
      io: StringIO.new('workflow stderr logs'),
      filename: 'stderr.txt',
      content_type: 'text/plain'
    )

    get workflow_execution_path(@workflow_execution_completed)
    assert_response :success

    assert_select 'dt', text: I18n.t('workflow_executions.summary.stdout')
    assert_select 'dt', text: I18n.t('workflow_executions.summary.stderr')
    assert_select 'a', text: 'stdout.txt'
    assert_select 'a', text: 'stderr.txt'
  end

  test 'should not show the workflow' do
    get workflow_execution_path(workflow_executions(:irida_next_example_completing_e))
    assert_response :not_found
  end

  test 'should not cancel a cancelable workflow with incorrect permissions' do
    sign_in users(:jane_doe)
    assert @workflow_execution_running.running?

    put cancel_workflow_execution_path(@workflow_execution_running), as: :turbo_stream
    assert_response :not_found

    assert_equal 'running', @workflow_execution_running.reload.state
  end

  test 'redirect to global workflow executions page when workflow execution is deleted' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    delete workflow_execution_path(workflow_execution, redirect: true), as: :turbo_stream
    assert_response :redirect

    assert_redirected_to workflow_executions_path
  end

  test 'Submitter can update workflow execution name post launch' do
    new_name = 'New Name'
    update_params = { workflow_execution: { name: new_name } }

    put workflow_execution_path(@workflow_execution_new), params: update_params, as: :turbo_stream

    assert_response :success
    assert_equal new_name, @workflow_execution_new.reload.name
    assert_turbo_stream_flash(
      I18n.t('concerns.workflow_execution_actions.update.success',
             workflow_name: @workflow_execution_new.workflow.name)
    )
    assert_select 'turbo-stream[action="replace"][target="workflow_execution_summary"]'
    assert_select 'turbo-stream[action="update"][target="we_name_header"]', text: /#{Regexp.escape(new_name)}/
  end

  test 'should open edit dialog' do
    get edit_workflow_execution_path(@workflow_execution_new, format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="edit_dialog"]' do
      assert_select 'h1', I18n.t('workflow_executions.edit_dialog.title')
      assert_select 'p', I18n.t('workflow_executions.edit_dialog.description',
                                workflow_execution_id: @workflow_execution_new.id)
      assert_select "input[placeholder='#{I18n.t('workflow_executions.edit_dialog.name_placeholder')}']"
    end
  end

  test 'should not update workflow execution with a blank name' do
    put workflow_execution_path(@workflow_execution_new),
        params: { workflow_execution: { name: '' } },
        as: :turbo_stream

    assert_response :unprocessable_content
    assert_equal 'irida_next_example_new', @workflow_execution_new.reload.name
    assert_select 'turbo-stream[action="update"][target="edit_dialog"]'
  end

  test 'Submitter can share the pipeline results post launch' do
    update_params = { workflow_execution: { shared_with_namespace: true } }

    put workflow_execution_path(@workflow_execution_new), params: update_params, as: :turbo_stream

    assert_response :success
    assert @workflow_execution_new.reload.shared_with_namespace
    assert_turbo_stream_flash(
      I18n.t('concerns.workflow_execution_actions.update.success',
             workflow_name: @workflow_execution_new.workflow.name)
    )
    assert_select 'turbo-stream[action="replace"][target="workflow_execution_summary"]'
  end

  test 'Cannot update another user\'s personal workflow execution name' do
    sign_in users(:ryan_doe)

    update_params = { workflow_execution: { name: 'New Name' } }

    put workflow_execution_path(@workflow_execution_new), params: update_params, as: :turbo_stream

    assert_response :not_found
  end

  test 'should open destroy_confirmation' do
    get destroy_confirmation_workflow_execution_path(@workflow_execution_completed, format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
      assert_select 'h1', I18n.t('shared.workflow_executions.destroy_confirmation_dialog.title')
    end
  end

  test 'should open destroy_multiple_confirmation' do
    get destroy_multiple_confirmation_workflow_executions_path(format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
      assert_select 'h1', I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.title')
    end
  end

  test 'should open cancel_multiple_confirmation' do
    get cancel_multiple_confirmation_workflow_executions_path(format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="update"][target="workflow_execution_dialog"]' do
      assert_select 'h1', I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.title')
    end
  end

  test 'should destroy multiple workflows at once' do
    assert_difference -> { WorkflowExecution.count } => -2,
                      -> { SamplesWorkflowExecution.count } => -2 do
                        post destroy_multiple_workflow_executions_path,
                             params: { destroy_multiple: { workflow_execution_ids:
                                                           [@workflow_execution_error.id,
                                                            @workflow_execution_canceled.id] } },
                             as: :turbo_stream
                      end
    assert_response :success
    assert_turbo_stream_flash(I18n.t('concerns.workflow_execution_actions.destroy_multiple.success'))
    assert_select 'turbo-stream[action="refresh"]'
  end

  test 'should partially destroy multiple workflows at once' do
    assert_difference -> { WorkflowExecution.count } => -2,
                      -> { SamplesWorkflowExecution.count } => -2 do
                        post destroy_multiple_workflow_executions_path,
                             params: { destroy_multiple: { workflow_execution_ids:
                                                           [@workflow_execution_error.id,
                                                            @workflow_execution_canceled.id,
                                                            @workflow_execution_new.id] } },
                             as: :turbo_stream
                      end
    assert_response :multi_status
  end

  test 'should not destroy multiple non-deletable workflows' do
    assert_no_difference -> { WorkflowExecution.count },
                         -> { SamplesWorkflowExecution.count } do
      post destroy_multiple_workflow_executions_path,
           params: { destroy_multiple: { workflow_execution_ids: [@workflow_execution_running.id,
                                                                  @workflow_execution_new.id] } },
           as: :turbo_stream
    end
    assert_response :unprocessable_content
  end

  test 'should cancel multiple workflows' do
    post cancel_multiple_workflow_executions_path,
         params: { cancel_multiple: { workflow_execution_ids: [@workflow_execution_running.id,
                                                               @workflow_execution_new.id] } },
         as: :turbo_stream
    assert_response :success
    assert_turbo_stream_flash(I18n.t('concerns.workflow_execution_actions.cancel_multiple.success'))
    assert_select 'turbo-stream[action="refresh"]'
  end

  test 'should partially cancel multiple workflows' do
    post cancel_multiple_workflow_executions_path,
         params: { cancel_multiple: { workflow_execution_ids: [@workflow_execution_running.id,
                                                               @workflow_execution_error.id] } },
         as: :turbo_stream
    assert_response :multi_status
  end

  test 'should not cancel multiple un-cancellable workflows' do
    post cancel_multiple_workflow_executions_path,
         params: { cancel_multiple: { workflow_execution_ids: [@workflow_execution_canceled.id,
                                                               @workflow_execution_error.id] } },
         as: :turbo_stream
    assert_response :unprocessable_content
  end

  test 'accessing workflow executions index on invalid page causes pagy overflow redirect at global level' do
    # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
    # The rescue_from handler should redirect to first page with page=1 and limit=20
    get workflow_executions_path(page: 50)

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
