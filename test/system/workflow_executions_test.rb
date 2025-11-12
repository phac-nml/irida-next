# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsTest < ApplicationSystemTestCase
  WORKFLOW_EXECUTION_COUNT = 18

  setup do
    @user = users(:john_doe)
    login_as @user

    @workflow_execution1 = workflow_executions(:irida_next_example_completed)
    @workflow_execution2 = workflow_executions(:irida_next_example_completed_2_files)
    @workflow_execution3 = workflow_executions(:irida_next_example_completed_with_output)
    @workflow_execution4 = workflow_executions(:irida_next_example_running)
    @workflow_execution5 = workflow_executions(:irida_next_example_new)

    @id_col = '1'
    @name_col = '2'
    @state_col = '3'
    @run_id_col = '4'
    @workflow_name_col = '5'
    @workflow_version_col = '6'
    @created_at_col = '7'

    Flipper.enable(:delete_multiple_workflows)
    Flipper.enable(:cancel_multiple_workflows)
  end

  test 'should display a list of workflow executions' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
  end

  test 'should display pages of workflow executions' do
    login_as users(:jane_doe)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_selector '#workflow-executions-table table tbody tr', count: 20

    assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
    assert_no_selector 'a',
                       exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
    click_on I18n.t(:'components.viral.pagy.pagination_component.next')
    assert_selector '#workflow-executions-table table tbody tr', count: 5

    assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
    assert_no_selector 'a',
                       exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
    click_on I18n.t(:'components.viral.pagy.pagination_component.previous')
    assert_selector '#workflow-executions-table table tbody tr', count: 20
  end

  test 'should sort a list of workflow executions' do
    workflow_execution = workflow_executions(:irida_next_example)
    workflow_execution1 = workflow_executions(:workflow_execution_valid)
    workflow_execution8 = workflow_executions(:irida_next_example_canceling)
    workflow_execution9 = workflow_executions(:irida_next_example_canceled)
    workflow_execution12 = workflow_executions(:irida_next_example_new)
    workflow_execution_shared1 = workflow_executions(:workflow_execution_shared1)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    click_on 'Run ID'
    assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.arrow-up-icon"

    within('#workflow-executions-table table tbody') do
      assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
      assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
      assert_selector "tr:nth-child(#{@run_id_col}) td:nth-child(#{@run_id_col})", text: workflow_execution12.run_id
      assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution.run_id
    end

    click_on 'Run ID'
    assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.arrow-down-icon"

    within('#workflow-executions-table table tbody') do
      assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
      assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution.run_id
      assert_selector "tr:nth-child(4) td:nth-child(#{@run_id_col})", text: workflow_execution_shared1.run_id
      assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
    end

    click_on 'Workflow Name'
    assert_selector "#workflow-executions-table table thead th:nth-child(#{@workflow_name_col}) svg.arrow-up-icon"

    within('#workflow-executions-table table tbody') do
      assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
      assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution9.workflow.name
      assert_selector "tr:nth-child(3) td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution8.workflow.name
      assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution_shared1.workflow.name
    end

    click_on 'Workflow Name'
    assert_selector "#workflow-executions-table table thead th:nth-child(#{@workflow_name_col}) svg.arrow-down-icon"

    within('#workflow-executions-table table tbody') do
      assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
      assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution_shared1.workflow.name
      assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution9.workflow.name
    end
  end

  test 'should include a shared workflow in the list of workflow executions when the submitter is the current user' do
    workflow_execution = workflow_executions(:workflow_execution_shared1)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_selector "tr[id='#{dom_id(workflow_execution)}']"
    within("tr[id='#{dom_id(workflow_execution)}'] td:last-child") do
      assert_button I18n.t('common.actions.cancel')
    end
  end

  test 'should not include a shared workflow in the workflow executions when the submitter is not the current user' do
    workflow_execution = workflow_executions(:workflow_execution_shared2)

    visit workflow_executions_path

    assert_selector '#workflow-executions-table'
    assert_no_selector "tr[id='#{dom_id(workflow_execution)}']"
  end

  test 'should be able to cancel a workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_button 'Cancel', count: 1
      click_button 'Cancel'
    end

    assert_text I18n.t('shared.workflow_executions.destroy_confirmation_dialog.title')
    click_button I18n.t('shared.workflow_executions.destroy_confirmation_dialog.submit_button')

    within %(div[data-controller='viral--flash']) do
      assert_text I18n.t(
        :'concerns.workflow_execution_actions.cancel.success',
        workflow_name: workflow_execution.workflow.name
      )
    end

    assert_selector "tbody tr td:nth-child(#{@state_col})", text: 'Canceling'
    assert_no_selector "tbody tr td:nth-child(#{@state_col}) a[text='Cancel']"
  end

  test 'should not delete a prepared workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'should not delete a submitted workflow' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'should not delete a unclean workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed_unclean)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'should delete a completed workflow' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    # Select all workflow executions within the table
    click_button I18n.t('common.controls.select_all')
    within 'tbody' do
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: WORKFLOW_EXECUTION_COUNT
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT
    end

    tr = find('a', text: @workflow_execution1.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{@workflow_execution1.state}")
      assert_button I18n.t('common.actions.delete'), count: 1
      click_button I18n.t('common.actions.delete')
    end

    assert_text I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.title')
    click_button I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.submit_button')

    within %(div[data-controller='viral--flash']) do
      assert_text I18n.t(
        :'concerns.workflow_execution_actions.destroy.success',
        workflow_name: @workflow_execution1.workflow.name
      )
    end

    assert_no_text @workflow_execution1.id

    # Verify all workflow executions within the table are still selected and the footer is updated
    within 'tbody' do
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: WORKFLOW_EXECUTION_COUNT - 1
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT - 1
    end
  end

  test 'should delete an errored workflow' do
    workflow_execution = workflow_executions(:irida_next_example_error)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_button I18n.t('common.actions.delete'), count: 1
      click_button I18n.t('common.actions.delete')
    end

    assert_text I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.title')
    click_button I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.submit_button')

    assert_no_text workflow_execution.id
  end

  test 'should not delete a canceling workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceling)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'should delete a canceled workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceled)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_button I18n.t('common.actions.delete'), count: 1
      click_button I18n.t('common.actions.delete')
    end

    assert_text I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.title')
    click_button I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.submit_button')

    assert_no_text workflow_execution.id
  end

  test 'should not delete a running workflow' do
    workflow_execution = workflow_executions(:irida_next_example_running)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'should not delete a new workflow' do
    workflow_execution = workflow_executions(:irida_next_example_new)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    tr = find('a', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link I18n.t('common.actions.delete')
    end
  end

  test 'can view a workflow execution' do
    workflow_execution = workflow_executions(:workflow_execution_existing)

    visit workflow_execution_path(workflow_execution, anchor: 'summary-tab')

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']

    click_on I18n.t('workflow_executions.show.tabs.files')

    assert_text I18n.t('workflow_executions.files.empty.title')
    assert_text I18n.t('workflow_executions.files.empty.description')

    click_on I18n.t('workflow_executions.show.tabs.params')

    assert_selector 'div.project_name-param > span', text: '--project_name'
    assert_selector 'div.project_name-param > input[value="assembly"]'

    assert_selector 'div.assembler-param > span', text: '--assembler'
    assert_selector 'div.assembler-param > input[value="stub"]'

    assert_selector 'div.random_seed-param > span', text: '--random_seed'
    assert_selector 'div.random_seed-param > input[value="1"]'
  end

  test 'can search workflow execution files by puid & filename' do
    Flipper.enable(:workflow_execution_attachments_searching)
    visit workflow_execution_path(@workflow_execution3, anchor: 'summary-tab')

    assert_text @workflow_execution3.id
    assert_text I18n.t(:"workflow_executions.state.#{@workflow_execution3.state}")
    assert_text @workflow_execution3.workflow.name
    assert_text @workflow_execution3.metadata['workflow_version']

    click_on I18n.t('workflow_executions.show.tabs.files')

    within 'tbody' do
      assert_text attachments(:samples_workflow_execution_completed_output_attachment).puid
      assert_text attachments(:workflow_execution_completed_output_attachment).puid
    end

    fill_in placeholder: I18n.t('workflow_executions.files.search.placeholder'),
            with: attachments(:samples_workflow_execution_completed_output_attachment).puid
    find('input.t-search-component').native.send_keys(:return)

    within 'tbody' do
      assert_text attachments(:samples_workflow_execution_completed_output_attachment).puid
      assert_no_text attachments(:workflow_execution_completed_output_attachment).puid
    end

    fill_in placeholder: I18n.t('workflow_executions.files.search.placeholder'),
            with: attachments(:workflow_execution_completed_output_attachment).file.filename.to_s
    find('input.t-search-component').native.send_keys(:return)

    within 'tbody' do
      assert_no_text attachments(:samples_workflow_execution_completed_output_attachment).puid
      assert_text attachments(:workflow_execution_completed_output_attachment).puid
    end
  end

  test 'can view workflow execution with samplesheet' do
    visit workflow_execution_path(@workflow_execution1, anchor: 'summary-tab')

    click_on I18n.t('workflow_executions.show.tabs.samplesheet')

    assert_selector 'table tbody tr', count: 1
    assert_text 'INXT_SAM_AAAAAAAAAA'
    assert_text 'INXT_ATT_AAAAAAAAAA'
    assert_text 'test_file_A.fastq'
  end

  test 'can view workflow execution with samplesheet with multiple files' do
    visit workflow_execution_path(@workflow_execution2, anchor: 'summary-tab')

    click_on I18n.t('workflow_executions.show.tabs.samplesheet')

    assert_selector 'table tbody tr', count: 1
    assert_text 'INXT_SAM_AAAAAAAAAA'
    assert_text 'INXT_ATT_AAAAAAAAAA'
    assert_text 'test_file_A.fastq'
    assert_text 'INXT_ATT_AAAAAAAAAB'
    assert_text 'test_file_A.fastq'
  end

  test 'can remove workflow execution from workflow execution page' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    # Select all workflow executions within the table
    click_button I18n.t('common.controls.select_all')
    within 'tbody' do
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: WORKFLOW_EXECUTION_COUNT
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT
    end

    visit workflow_execution_path(@workflow_execution1, anchor: 'summary-tab')

    click_button I18n.t('common.actions.remove')

    within('dialog[open]') do
      assert_text I18n.t('shared.workflow_executions.destroy_confirmation_dialog.title')
      click_button I18n.t('shared.workflow_executions.destroy_confirmation_dialog.submit_button')
    end

    assert_no_text @workflow_execution1.id

    # Verify all workflow executions within the table are still selected and the footer is updated
    within 'tbody' do
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: WORKFLOW_EXECUTION_COUNT - 1
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT - 1
    end
  end

  test 'can filter by ID and name on workflow execution index page' do
    visit workflow_executions_path

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector 'table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within('table tbody') do
      assert_text @workflow_execution2.id
      assert_text @workflow_execution2.name
      assert_text @workflow_execution3.id
      assert_text @workflow_execution3.name
    end

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: @workflow_execution2.id
    find('input.t-search-component').native.send_keys(:return)

    assert_text 'Displaying 1 item'
    assert_selector 'table tbody tr', count: 1

    within('table tbody') do
      assert_text @workflow_execution2.id
      assert_text @workflow_execution2.name
      assert_no_text @workflow_execution3.id
      assert_no_text @workflow_execution3.name
    end

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: ''
    find('input.t-search-component').native.send_keys(:return)

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector 'table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: @workflow_execution3.name
    find('input.t-search-component').native.send_keys(:return)

    assert_text 'Displaying 1 item'
    assert_selector 'table tbody tr', count: 1

    within('table tbody') do
      assert_no_text @workflow_execution2.id
      assert_no_text @workflow_execution2.name
      assert_text @workflow_execution3.id
      assert_text @workflow_execution3.name
    end
  end

  test 'submitter can edit workflow execution post launch from workflow execution page' do
    ### SETUP START ###
    Flipper.enable(:workflow_execution_sharing)
    workflow_execution = workflow_executions(:irida_next_example_new)
    visit workflow_execution_path(workflow_execution, anchor: 'summary-tab')
    dt_value = I18n.t('common.labels.name', locale: @user.locale)
    new_we_name = 'New Name'
    ### SETUP END ###

    ### VERIFY START ###
    assert_selector 'h1', text: workflow_execution.name
    assert_selector 'dt', exact_text: dt_value
    assert_no_selector 'dt', text: I18n.t(:"workflow_executions.summary.shared_with_namespace.#{workflow_execution.namespace.type.downcase}") # rubocop:disable Layout/LineLength
    assert_selector 'dt', text: I18n.t(:"workflow_executions.summary.run_from_namespace.#{workflow_execution.namespace.type.downcase}") # rubocop:disable Layout/LineLength
    assert_selector 'dd', text: workflow_execution.namespace.name
    assert_selector 'dd', text: workflow_execution.namespace.puid
    ### VERIFY END ###

    ### ACTIONS START ###
    assert_selector 'button', text: I18n.t('common.actions.edit'), count: 1
    click_button I18n.t('common.actions.edit')

    within('dialog') do
      assert_selector 'h1', text: I18n.t('workflow_executions.edit_dialog.title')
      assert_selector 'p', text: I18n.t('workflow_executions.edit_dialog.description',
                                        workflow_execution_id: workflow_execution.id)
      assert_selector 'label', text: dt_value
      fill_in placeholder: I18n.t('workflow_executions.edit_dialog.name_placeholder'),
              with: new_we_name

      assert_not find("input[type='checkbox']").checked?
      check I18n.t(:"workflow_executions.edit_dialog.shared_with_namespace.#{workflow_execution.namespace.type.downcase}") # rubocop:disable Layout/LineLength

      click_button I18n.t(:'workflow_executions.edit_dialog.submit_button')
    end
    ### ACTIONS END ###

    ### VERIFY START ###
    assert_selector 'h1', text: new_we_name
    assert_selector 'dt', text: dt_value
    assert_selector 'dd', text: new_we_name
    assert_no_selector 'dt', text: I18n.t(:"workflow_executions.summary.run_from_namespace.#{workflow_execution.namespace.type.downcase}") # rubocop:disable Layout/LineLength
    assert_selector 'dt', text: I18n.t(:"workflow_executions.summary.shared_with_namespace.#{workflow_execution.namespace.type.downcase}") # rubocop:disable Layout/LineLength
    assert_selector 'dd', text: workflow_execution.namespace.name
    assert_selector 'dd', text: workflow_execution.namespace.puid

    ### VERIFY END ###
  end

  test 'can view a shared workflow execution that the current user submitted' do
    workflow_execution = workflow_executions(:workflow_execution_shared1)

    visit workflow_execution_path(workflow_execution, anchor: 'summary-tab')

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']

    assert_selector 'button[disabled]', text: I18n.t(:'workflow_executions.show.create_export_button')
    assert_button I18n.t('common.actions.cancel')
    assert_button I18n.t('common.actions.edit')
    assert_no_button I18n.t('common.actions.remove')
  end

  test 'can successfully delete multiple workflows at once' do
    error_workflow = workflow_executions(:irida_next_example_error)
    canceled_workflow = workflow_executions(:irida_next_example_canceled)
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{error_workflow.id}']").click
      find("input[type='checkbox'][value='#{canceled_workflow.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution2.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.description.plural')
                      .gsub! 'COUNT_PLACEHOLDER', '3'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{error_workflow.id}"
        assert_text "ID: #{canceled_workflow.id}"
        assert_text "ID: #{@workflow_execution2.id}"
      end
      click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT - 3} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT - 3
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.success')
  end

  test 'can partially delete multiple workflows at once' do
    # attempt to destroy deletable and non-deletable workflows
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution2.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution3.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.description.plural')
                      .gsub! 'COUNT_PLACEHOLDER', '3'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{@workflow_execution1.id}"
        assert_text "ID: #{@workflow_execution2.id}"
        assert_text "ID: #{@workflow_execution3.id}"
      end
      click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT - 2} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT - 2
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.partial_error', unsuccessful: '1/3')
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.partial_success', successful: '2/3')
  end

  test 'cannot delete non-deletable workflows' do
    workflow_execution1 = workflow_executions(:irida_next_example_completed_unclean)
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{workflow_execution1.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{workflow_execution1.id}"
      end
      click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.error')
  end

  test 'can preview workflow execution files' do
    Flipper.enable(:attachments_preview)
    Flipper.enable(:workflow_execution_attachments_searching)

    visit workflow_execution_path(@workflow_execution3, anchor: 'summary-tab')

    click_on I18n.t('workflow_executions.show.tabs.files')

    within 'tbody' do
      assert_link I18n.t('components.attachments.table_component.preview')
      click_link I18n.t('components.attachments.table_component.preview'), match: :first
    end

    # Should navigate to attachment preview page
    assert_current_path(%r{/attachments/\d+})
    assert_selector 'h1'
  end

  test 'can successfully cancel multiple workflows at once' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution5.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.description.plural')
                      .gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{error_workflow.id}"
        assert_text "ID: #{canceled_workflow.id}"
      end
      click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.success')
  end

  test 'can partially cancel multiple workflows at once' do
    # attempt to cancel cancellable and non-cancellable workflows
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
      find("input[type='checkbox'][value='#{@workflow_execution5.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.description.plural')
                      .gsub! 'COUNT_PLACEHOLDER', '3'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{@workflow_execution1.id}"
        assert_text "ID: #{@workflow_execution4.id}"
        assert_text "ID: #{@workflow_execution5.id}"
      end
      click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.partial_error', unsuccessful: '1/3')
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.partial_success', successful: '2/3')
  end

  test 'cannot cancel non-cancellable workflows' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

    within 'table' do
      find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')

    assert_selector '#dialog'
    within('#dialog') do
      assert_text I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.description.singular')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.state_warning_html')
      )
      within('#list_selections') do
        assert_text "ID: #{@workflow_execution1.id}"
      end
      click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
    assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.error')
  end
end
