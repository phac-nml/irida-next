# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsTest < ApplicationSystemTestCase
  WORKFLOW_EXECUTION_COUNT = 22
  PAGE_SIZE = 20

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

    Flipper.enable(:cancel_multiple_workflows)
  end

  test 'should display a list of workflow executions' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE
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

    assert_text I18n.t('workflow_executions.actions.cancel_confirm')
    click_button I18n.t('common.controls.confirm')

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
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: PAGE_SIZE
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
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: PAGE_SIZE
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

    visit workflow_execution_path(workflow_execution)

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']
    assert_link workflow_execution.namespace.name
    assert_text workflow_execution.namespace.puid
    assert_no_text I18n.t('workflow_executions.summary.deleted')

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

  test 'can view a workflow execution of a deleted project' do
    workflow_execution = workflow_executions(:workflow_execution_existing)
    project = workflow_execution.namespace.project

    Projects::DestroyService.new(project, @user).execute
    assert project.deleted?

    visit workflow_execution_path(workflow_execution, anchor: 'summary-tab')

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']
    assert_no_link workflow_execution.namespace.name
    assert_text workflow_execution.namespace.name
    assert_text workflow_execution.namespace.puid
    assert_text I18n.t('workflow_executions.summary.deleted')

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

  test 'can view a workflow execution of a deleted group' do
    workflow_execution = workflow_executions(:workflow_execution_existing)
    group = workflow_execution.namespace.parent

    Groups::DestroyService.new(group, @user).execute
    assert group.deleted?

    visit workflow_execution_path(workflow_execution, anchor: 'summary-tab')

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']
    assert_no_link workflow_execution.namespace.name
    assert_text workflow_execution.namespace.name
    assert_text workflow_execution.namespace.puid
    assert_text I18n.t('workflow_executions.summary.deleted')

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
    visit workflow_execution_path(@workflow_execution3)

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
    find('input.t-search-component').send_keys(:return)

    within 'tbody' do
      assert_text attachments(:samples_workflow_execution_completed_output_attachment).puid
      assert_no_text attachments(:workflow_execution_completed_output_attachment).puid
    end

    fill_in placeholder: I18n.t('workflow_executions.files.search.placeholder'),
            with: attachments(:workflow_execution_completed_output_attachment).file.filename.to_s
    find('input.t-search-component').send_keys(:return)

    within 'tbody' do
      assert_no_text attachments(:samples_workflow_execution_completed_output_attachment).puid
      assert_text attachments(:workflow_execution_completed_output_attachment).puid
    end
  end

  test 'can view workflow execution with samplesheet' do
    visit workflow_execution_path(@workflow_execution1)

    click_on I18n.t('workflow_executions.show.tabs.samplesheet')

    assert_selector 'table tbody tr', count: 1
    assert_text 'INXT_SAM_AAAAAAAAAA'
    assert_text 'INXT_ATT_AAAAAAAAAA'
    assert_text 'test_file_A.fastq'
  end

  test 'can view workflow execution with samplesheet with multiple files' do
    visit workflow_execution_path(@workflow_execution2)

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
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: PAGE_SIZE
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT
    end

    visit workflow_execution_path(@workflow_execution1)

    click_button I18n.t('common.actions.remove')

    within('dialog[open]') do
      assert_text I18n.t('shared.workflow_executions.destroy_confirmation_dialog.title')
      click_button I18n.t('shared.workflow_executions.destroy_confirmation_dialog.submit_button')
    end

    assert_no_text @workflow_execution1.id

    # Verify all workflow executions within the table are still selected and the footer is updated
    within 'tbody' do
      assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: PAGE_SIZE
    end
    within 'tfoot' do
      assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT - 1
    end
  end

  test 'can filter by ID and name on workflow execution index page' do
    visit workflow_executions_path

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector 'table tbody tr', count: PAGE_SIZE

    within('table tbody') do
      assert_text @workflow_execution2.id
      assert_text @workflow_execution2.name
      assert_text @workflow_execution3.id
      assert_text @workflow_execution3.name
    end

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: @workflow_execution2.id
    find('input.t-search-component').send_keys(:return)

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
    find('input.t-search-component').send_keys(:return)

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector 'table tbody tr', count: PAGE_SIZE

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: @workflow_execution3.name
    find('input.t-search-component').send_keys(:return)

    assert_text 'Displaying 1 item'
    assert_selector 'table tbody tr', count: 1

    within('table tbody') do
      assert_no_text @workflow_execution2.id
      assert_no_text @workflow_execution2.name
      assert_text @workflow_execution3.id
      assert_text @workflow_execution3.name
    end
  end

  test 'workflow advanced search is hidden when workflow advanced-search feature flag is disabled' do
    Flipper.disable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    assert_no_button I18n.t(:'components.advanced_search_component.v1.title')

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: @workflow_execution1.id
    find('input.t-search-component').send_keys(:return)

    assert_text 'Displaying 1 item'
    assert_selector 'table tbody tr', count: 1
    assert_text @workflow_execution1.id
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search filters results when workflow advanced-search feature flag is enabled' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    assert_button I18n.t(:'components.advanced_search_component.v1.title')

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    within('dialog') do
      assert_selector "[name='q[groups_attributes][0][conditions_attributes][0][field]']", visible: :all

      if has_selector?("input[role='combobox']", visible: :visible)
        find("input[role='combobox']", visible: :visible).send_keys(
          I18n.t('workflow_executions.table_component.state'),
          :enter
        )
      else
        find("select[name$='[field]']", visible: :visible).find("option[value='state']").select_option
      end
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option
      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(
          I18n.t('workflow_executions.state.completed')
        )
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: I18n.t('workflow_executions.state.completed')
      end
      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_no_selector 'dialog[open] h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.v1.clear_aria_label')}']"
    assert_selector "div[role='status']", text: /advanced search/, visible: false
    assert_text @workflow_execution1.id
    assert_no_text @workflow_execution4.id
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search returns no results for invalid enum state value' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    within('dialog') do
      if has_selector?("input[role='combobox']", visible: :visible)
        find("input[role='combobox']", visible: :visible).send_keys(
          I18n.t('workflow_executions.table_component.state'),
          :enter
        )
      else
        find("select[name$='[field]']", visible: :visible).find("option[value='state']").select_option
      end
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option
      unless has_selector?("select[name$='[value]']", visible: :visible)
        find("input[name$='[value]']", visible: :visible).fill_in with: 'nonexistent_state_value'
        click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
      end
    end

    if has_no_selector?("select[name$='[value]']", visible: :visible)
      assert_no_selector 'dialog[open] h1', text: I18n.t(:'components.advanced_search_component.v1.title')
      assert_selector "div[role='status']", text: /advanced search/, visible: false
      assert_text 'Displaying 0 items'
    end
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow quick search preserves active advanced search when feature flag is enabled' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      if has_selector?("input[role='combobox']", visible: :visible)
        find("input[role='combobox']", visible: :visible).send_keys(
          I18n.t('workflow_executions.table_component.state'),
          :enter
        )
      else
        find("select[name$='[field]']", visible: :visible).find("option[value='state']").select_option
      end
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option
      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end
      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
            with: 'irida_next_example'
    find('input.t-search-component').send_keys(:return)

    assert_button I18n.t(:'components.search_field_component.clear_button')

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')
    assert_selector "div[role='status']", text: /advanced search/, visible: false
    assert_text @workflow_execution1.id
    assert_no_text @workflow_execution4.id

    # clicking clear button on quick search should clear quick search but preserve advanced search
    click_button I18n.t(:'components.search_field_component.clear_button')

    assert_no_button I18n.t(:'components.search_field_component.clear_button')
    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search keeps completed results visible when broadening state not_in filters' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='not_in']").select_option
      set_advanced_search_multi_select_values(
        "select[name$='[value][]']",
        %w[initial prepared submitted]
      )

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    assert_text @workflow_execution1.id
    assert_no_text @workflow_execution5.id

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      set_advanced_search_multi_select_values(
        "select[name$='[value][]']",
        %w[initial prepared submitted running completing error canceling canceled]
      )

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    assert_text @workflow_execution1.id
    assert_no_text @workflow_execution4.id
    assert_no_text @workflow_execution5.id
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search clears form on close when there is no active search' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end

      find('button.dialog--close', visible: :visible).click
    end

    assert_no_selector 'dialog[open] h1', text: I18n.t(:'components.advanced_search_component.v1.title')

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible, count: 1

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[0] do
        assert_equal '', find("select[name$='[operator]']", visible: :visible).value
        assert_equal '', find("input[name$='[value]']", visible: :all).value
      end
    end
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search retains applied state with multiple conditions when reopening dialog' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end

      click_button I18n.t(:'components.advanced_search_component.v1.add_condition_button')

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[1] do
        if has_selector?("input[role='combobox']", visible: :visible)
          find("input[role='combobox']", visible: :visible).send_keys(
            I18n.t('workflow_executions.table_component.run_id'),
            :enter
          )
        else
          find("select[name$='[field]']", visible: :visible).find("option[value='run_id']").select_option
        end

        find("select[name$='[operator]']", visible: :visible).find("option[value='contains']").select_option
        find("input[name$='[value]']", visible: :visible).fill_in with: 'my_run_id'
      end

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible, count: 2

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[0] do
        assert_equal '=', find("select[name$='[operator]']", visible: :visible).value

        if has_selector?("select[name$='[value]']", visible: :visible)
          assert_equal 'completed', find("select[name$='[value]']", visible: :visible).value
        else
          assert_equal 'completed', find("input[name$='[value]']", visible: :visible).value
        end
      end

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[1] do
        assert_equal 'contains', find("select[name$='[operator]']", visible: :visible).value
        assert_equal 'my_run_id', find("input[name$='[value]']", visible: :visible).value
      end
    end
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search resets to applied state on close when active search exists' do
    Flipper.enable(:workflow_execution_advanced_search)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      click_button I18n.t(:'components.advanced_search_component.v1.add_condition_button')

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[1] do
        if has_selector?("input[role='combobox']", visible: :visible)
          find("input[role='combobox']", visible: :visible).send_keys(
            I18n.t('workflow_executions.table_component.run_id'),
            :enter
          )
        else
          find("select[name$='[field]']", visible: :visible).find("option[value='run_id']").select_option
        end

        find("select[name$='[operator]']", visible: :visible).find("option[value='contains']").select_option
        find("input[name$='[value]']", visible: :visible).fill_in with: 'draft_run_id'
      end

      accept_confirm do
        find('button.dialog--close', visible: :visible).click
      end
    end

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      assert_selector "fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible, count: 1

      within all("fieldset[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)[0] do
        assert_equal '=', find("select[name$='[operator]']", visible: :visible).value
      end

      assert_no_selector "fieldset[data-advanced-search--v1-target='conditionsContainer'] input[value='draft_run_id']",
                         visible: :all
    end
  ensure
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'workflow advanced search retains operator and value after reopen with autocomplete enabled' do
    Flipper.enable(:workflow_execution_advanced_search)
    Flipper.enable(:advanced_search_with_auto_complete, @user)

    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_button I18n.t(:'components.advanced_search_component.v1.clear_aria_label')

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    within('dialog') do
      assert_equal '=', find("select[name$='[operator]']", visible: :visible).value

      if has_selector?("select[name$='[value]']", visible: :visible)
        assert_equal 'completed', find("select[name$='[value]']", visible: :visible).value
      else
        assert_equal 'completed', find("input[name$='[value]']", visible: :visible).value
      end
    end
  ensure
    Flipper.disable(:advanced_search_with_auto_complete, @user)
    Flipper.disable(:workflow_execution_advanced_search)
  end

  test 'submitter can edit workflow execution post launch from workflow execution page' do
    ### SETUP START ###
    workflow_execution = workflow_executions(:irida_next_example_new)
    visit workflow_execution_path(workflow_execution)
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

    visit workflow_execution_path(workflow_execution)

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.workflow.name
    assert_text workflow_execution.metadata['workflow_version']
    assert_link workflow_execution.namespace.name
    assert_text workflow_execution.namespace.puid
    assert_no_text I18n.t('workflow_executions.summary.deleted')

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE
    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.error')
  end

  test 'can preview workflow execution files' do
    Flipper.enable(:workflow_execution_attachments_searching)

    previewable_attachment = attachments(:samples_workflow_execution_completed_output_attachment)

    visit workflow_execution_path(@workflow_execution3)

    click_on I18n.t('workflow_executions.show.tabs.files')

    within 'tbody' do
      assert_link I18n.t('components.attachments.table_component.preview_aria_label',
                         name: previewable_attachment.file.filename.to_s)
      click_link I18n.t('components.attachments.table_component.preview_aria_label',
                        name: previewable_attachment.file.filename.to_s)
    end

    # Should navigate to attachment preview page
    assert_selector 'h1', text: previewable_attachment.file.filename.to_s
    assert_current_path(%r{/attachments/\d+})
  end

  test 'can successfully cancel multiple workflows at once' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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
        assert_text "ID: #{@workflow_execution4.id}"
        assert_text "ID: #{@workflow_execution5.id}"
      end
      click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
    end

    assert_no_selector '#dialog'

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.success')
  end

  test 'can partially cancel multiple workflows at once' do
    # attempt to cancel cancellable and non-cancellable workflows
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.partial_error', unsuccessful: '1/3')
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.partial_success', successful: '2/3')
  end

  test 'cannot cancel non-cancellable workflows' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE

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

    assert_text "Displaying items 1-#{PAGE_SIZE} of #{WORKFLOW_EXECUTION_COUNT} in total"
    assert_selector '#workflow-executions-table table tbody tr', count: PAGE_SIZE
    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.error')
  end

  private

  def select_state_advanced_search_field
    if has_selector?("input[role='combobox']", visible: :visible)
      find("input[role='combobox']", visible: :visible).send_keys(
        I18n.t('workflow_executions.table_component.state'),
        :enter
      )
    else
      find("select[name$='[field]']", visible: :visible).find("option[value='state']").select_option
    end
  end

  def set_advanced_search_multi_select_values(selector, values)
    return apply_select_values(find(selector, visible: :visible), values) if has_selector?(selector, visible: :visible)
    return apply_select_values(find(selector, visible: :all), values) if has_selector?(selector, visible: :all)
    return apply_list_filter_values(values) if has_selector?("div[data-controller='list-filter']", visible: :visible)

    apply_hidden_input_values(values)
  end

  def apply_select_values(select, values)
    page.execute_script(<<~JS, select)
      const element = arguments[0];
      const values = #{values.to_json};
      Array.from(element.options).forEach((option) => { option.selected = values.includes(option.value); });
      element.dispatchEvent(new Event("input", { bubbles: true }));
      element.dispatchEvent(new Event("change", { bubbles: true }));
    JS
  end

  def apply_list_filter_values(values) # rubocop:disable Metrics/MethodLength
    list_filter = find("div[data-controller='list-filter']", visible: :visible)

    page.execute_script(<<~JS, list_filter)
      const element = arguments[0];
      const values = #{values.to_json};
      const template = element.querySelector("template[data-list-filter-target='template']");
      const tags = element.querySelector("[data-list-filter-target='tags']");
      const input = element.querySelector("[data-list-filter-target='input']");

      if (!template || !tags || !input) { return; }

      while (tags.firstChild && tags.firstChild !== input) { tags.firstChild.remove(); }

      values.forEach((value) => {
        if (!value) { return; }
        const clone = template.content.cloneNode(true);
        const hiddenInput = clone.querySelector("input[name$='[value][]']");
        const label = clone.querySelector(".label");
        if (hiddenInput) { hiddenInput.value = value; }
        if (label) { label.textContent = value; }
        tags.insertBefore(clone, input);
      });

      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
    JS
  end

  def apply_hidden_input_values(values) # rubocop:disable Metrics/MethodLength
    condition = find("[data-advanced-search--v1-target='conditionsContainer']", visible: :visible)
    operator_select = condition.find("select[name$='[operator]']", visible: :all)
    input_name = operator_select[:name].sub(/\[operator\]\z/, '[value][]')

    page.execute_script(<<~JS, condition, input_name)
      const conditionElement = arguments[0];
      const inputName = arguments[1];
      const values = #{values.to_json};

      conditionElement.querySelectorAll("input, select").forEach((element) => {
        if (element.name === inputName) { element.remove(); }
      });

      values.forEach((value) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = inputName;
        input.value = value;
        conditionElement.appendChild(input);
      });
    JS
  end
end
