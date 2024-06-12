# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user

    @id_col = '1'
    @name_col = '2'
    @state_col = '3'
    @run_id_col = '4'
    @workflow_name_col = '5'
    @workflow_version_col = '6'
    @created_at_col = '7'
  end

  test 'should display a list of workflow executions' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    assert_selector 'table#workflow_executions tbody tr', count: 17
  end

  test 'should display pages of workflow executions' do
    login_as users(:jane_doe)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    assert_selector 'table#workflow_executions tbody tr', count: 20

    assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
    assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')
    click_on I18n.t(:'components.pagination.next')
    assert_selector 'table#workflow_executions tbody tr', count: 5

    assert_selector 'a', text: I18n.t(:'components.pagination.previous')
    assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
    click_on I18n.t(:'components.pagination.previous')
    assert_selector 'table#workflow_executions tbody tr', count: 20
  end

  test 'should sort a list of workflow executions' do
    workflow_execution = workflow_executions(:irida_next_example)
    workflow_execution1 = workflow_executions(:workflow_execution_valid)
    workflow_execution2 = workflow_executions(:workflow_execution_invalid_metadata)
    workflow_execution8 = workflow_executions(:irida_next_example_canceling)
    workflow_execution9 = workflow_executions(:irida_next_example_canceled)
    workflow_execution10 = workflow_executions(:workflow_execution_existing)
    workflow_execution12 = workflow_executions(:irida_next_example_new)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    click_on I18n.t('workflow_executions.table.headers.run_id')
    assert_selector "table#workflow_executions thead th:nth-child(#{@run_id_col}) svg.icon-arrow_up"

    within first('table#workflow_executions tbody') do
      assert_selector 'tr', count: 17
      assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
      assert_selector "tr:nth-child(#{@run_id_col}) td:nth-child(#{@run_id_col})", text: workflow_execution10.run_id
      assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution.run_id
    end

    click_on I18n.t('workflow_executions.table.headers.run_id')
    assert_selector "table#workflow_executions thead th:nth-child(#{@run_id_col}) svg.icon-arrow_down"

    within first('table#workflow_executions tbody') do
      assert_selector 'tr', count: 17
      assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution.run_id
      assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: workflow_execution9.run_id
      assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
    end

    click_on I18n.t('workflow_executions.table.headers.workflow_name')
    assert_selector "table#workflow_executions thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_up"

    within first('table#workflow_executions tbody') do
      assert_selector 'tr', count: 17
      assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution9.metadata['workflow_name']
      assert_selector "tr:nth-child(3) td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution8.metadata['workflow_name']
      assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution1.metadata['workflow_name']
    end

    click_on I18n.t('workflow_executions.table.headers.workflow_name')
    assert_selector "table#workflow_executions thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_down"

    within first('table#workflow_executions tbody') do
      assert_selector 'tr', count: 17
      assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution1.metadata['workflow_name']
      assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution2.metadata['workflow_name']
      assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                      text: workflow_execution9.metadata['workflow_name']
    end

    click_on I18n.t('workflow_executions.table.headers.created_at')
    assert_selector "table#workflow_executions thead th:nth-child(#{@created_at_col}) svg.icon-arrow_up"

    within first('table#workflow_executions tbody') do
      assert_selector 'tr', count: 17
      assert_selector "tr:first-child td:nth-child(#{@created_at_col})",
                      text: I18n.l(workflow_execution1.created_at.localtime, format: :full_date)
      assert_selector "tr:nth-child(2) td:nth-child(#{@created_at_col})",
                      text: I18n.l(workflow_execution2.created_at.localtime, format: :full_date)
      assert_selector "tr:last-child td:nth-child(#{@created_at_col})",
                      text: I18n.l(workflow_execution12.created_at.localtime, format: :full_date)
    end
  end

  test 'should be able to cancel a workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_link 'Cancel', count: 1
      click_link 'Cancel'
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    within %(div[data-controller='viral--flash']) do
      assert_text I18n.t(
        :'workflow_executions.cancel.success',
        workflow_name: workflow_execution.metadata['workflow_name']
      )
    end

    assert_selector "tbody tr td:nth-child(#{@state_col})", text: 'Canceling'
    assert_no_selector "tbody tr td:nth-child(#{@state_col}) a[text='Cancel']"
  end

  test 'should not delete a prepared workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'should not delete a submitted workflow' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'should not delete a unclean workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed_unclean)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'should delete a completed workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_link 'Delete', count: 1
      click_link 'Delete'
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    within %(div[data-controller='viral--flash']) do
      assert_text I18n.t(
        :'workflow_executions.destroy.success',
        workflow_name: workflow_execution.metadata['workflow_name']
      )
    end

    assert_no_text workflow_execution.id
  end

  test 'should delete an errored workflow' do
    workflow_execution = workflow_executions(:irida_next_example_error)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_link 'Delete', count: 1
      click_link 'Delete'
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_no_text workflow_execution.id
  end

  test 'should not delete a canceling workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceling)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'should delete a canceled workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceled)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_link 'Delete', count: 1
      click_link 'Delete'
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_no_text workflow_execution.id
  end

  test 'should not delete a running workflow' do
    workflow_execution = workflow_executions(:irida_next_example_running)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'should not delete a new workflow' do
    workflow_execution = workflow_executions(:irida_next_example_new)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector "td:nth-child(#{@state_col})",
                      text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_no_link 'Delete'
    end
  end

  test 'can view a workflow execution' do
    workflow_execution = workflow_executions(:workflow_execution_existing)

    visit workflow_execution_path(workflow_execution)

    assert_text workflow_execution.id
    assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    assert_text workflow_execution.metadata['workflow_name']
    assert_text workflow_execution.metadata['workflow_version']

    click_on I18n.t('workflow_executions.show.tabs.files')

    assert_text 'FILENAME'

    click_on I18n.t('workflow_executions.show.tabs.params')

    assert_selector 'div.project_name-param > span', text: '--project_name'
    assert_selector 'div.project_name-param > input[value="assembly"]'

    assert_selector 'div.assembler-param > span', text: '--assembler'
    assert_selector 'div.assembler-param > input[value="stub"]'

    assert_selector 'div.random_seed-param > span', text: '--random_seed'
    assert_selector 'div.random_seed-param > input[value="1"]'
  end

  test 'can view workflow execution with samples' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    visit workflow_execution_path(workflow_execution)

    click_on I18n.t('workflow_executions.show.tabs.samples')

    assert_selector 'table tbody tr', count: 1
    assert_text 'INXT_SAM_AAAAAAAAAA'
    assert_text 'INXT_ATT_AAAAAAAAAA'
    assert_text 'test_file.fastq'
  end

  test 'can remove workflow execution from workflow execution page' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    visit workflow_execution_path(workflow_execution)

    click_link I18n.t(:'workflow_executions.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#workflow_executions-table-body) do
      assert_selector 'tr', count: 16
      assert_no_text workflow_execution.id
    end
  end
end
