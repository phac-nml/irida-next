# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class WorkflowExecutionsTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @group = groups(:group_one)
      @workflow_execution_group_shared1 = workflow_executions(:workflow_execution_group_shared1)
      @workflow_execution_group_shared2 = workflow_executions(:workflow_execution_group_shared2)
      @workflow_execution_group_shared3 = workflow_executions(:workflow_execution_group_shared3)

      @id_col = '1'
      @name_col = '2'
      @state_col = '3'
      @run_id_col = '4'
      @workflow_name_col = '5'
      @workflow_version_col = '6'
      @created_at_col = '7'

      Flipper.enable(:workflow_execution_sharing)
    end

    test 'should display a list of workflow executions' do
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'groups.workflow_executions.index.subtitle')

      assert_selector '#workflow-executions-table table tbody tr', count: 11
    end

    test 'should sort a list of workflow executions' do
      workflow_execution_running = workflow_executions(:workflow_execution_group_shared_running)
      workflow_execution_prepared = workflow_executions(:workflow_execution_group_shared_prepared)
      workflow_execution_submitted = workflow_executions(:workflow_execution_group_shared_submitted)
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'groups.workflow_executions.index.subtitle')

      click_on 'Run ID'
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_up"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 11
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution_running.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: workflow_execution_prepared.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared3.run_id
      end

      click_on 'Run ID'
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_down"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 11
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared3.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared2.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution_running.run_id
      end

      click_on I18n.t(:'workflow_executions.table_component.workflow_name')
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_up"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 11
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared1.metadata['workflow_name']
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared2.metadata['workflow_name']
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared3.metadata['workflow_name']
      end

      click_on I18n.t(:'workflow_executions.table_component.workflow_name')
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_down"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 11
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution_running.metadata['workflow_name']
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution_submitted.metadata['workflow_name']
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared1.metadata['workflow_name']
      end
    end

    test 'should only include workflows that have been shared to the group' do
      workflow_execution1 = workflow_executions(:workflow_execution_shared1)
      workflow_execution2 = workflow_executions(:workflow_execution_shared2)

      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      assert_selector '#workflow-executions-table'

      assert_selector "tr[id='#{@workflow_execution_group_shared1.id}']"
      within("tr[id='#{@workflow_execution_group_shared1.id}'] td:last-child") do
        assert_no_link I18n.t(:'workflow_executions.index.actions.cancel_button')
        assert_no_link I18n.t(:'workflow_executions.index.actions.delete_button')
      end

      assert_selector "tr[id='#{@workflow_execution_group_shared2.id}']"
      within("tr[id='#{@workflow_execution_group_shared2.id}'] td:last-child") do
        assert_no_link I18n.t(:'workflow_executions.index.actions.cancel_button')
        assert_no_link I18n.t(:'workflow_executions.index.actions.delete_button')
      end

      assert_no_selector "tr[id='#{workflow_execution1.id}']"
      assert_no_selector "tr[id='#{workflow_execution2.id}']"
    end

    test 'can view a workflow execution' do
      login_as users(:joan_doe)
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      within("tr[id='#{@workflow_execution_group_shared1.id}'] th") do
        click_link @workflow_execution_group_shared1.id
      end

      assert_text @workflow_execution_group_shared1.id
      assert_text I18n.t(:"workflow_executions.state.#{@workflow_execution_group_shared1.state}")
      assert_text @workflow_execution_group_shared1.metadata['workflow_name']
      assert_text @workflow_execution_group_shared1.metadata['workflow_version']

      within %(div[id="workflow-execution-tabs"]) do
        click_on I18n.t('workflow_executions.show.tabs.files')
      end

      assert_text 'FILENAME'

      click_on I18n.t('workflow_executions.show.tabs.params')

      assert_selector 'div.project_name-param > span', text: '--project_name'
      assert_selector 'div.project_name-param > input[value="assembly"]'

      assert_selector 'div.assembler-param > span', text: '--assembler'
      assert_selector 'div.assembler-param > input[value="stub"]'

      assert_selector 'div.random_seed-param > span', text: '--random_seed'
      assert_selector 'div.random_seed-param > input[value="1"]'
    end

    test 'can view a shared workflow execution that was shared by a different user' do
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      within("tr[id='#{@workflow_execution_group_shared2.id}'] th") do
        click_link @workflow_execution_group_shared2.id
      end

      assert_text @workflow_execution_group_shared2.id
      assert_text I18n.t(:"workflow_executions.state.#{@workflow_execution_group_shared2.state}")
      assert_text @workflow_execution_group_shared2.metadata['workflow_name']
      assert_text @workflow_execution_group_shared2.metadata['workflow_version']

      assert_link I18n.t(:'workflow_executions.show.create_export_button')
      assert_no_link I18n.t(:'workflow_executions.show.cancel_button')
      assert_no_link I18n.t(:'workflow_executions.show.edit_button')
      assert_no_link I18n.t(:'workflow_executions.show.remove_button')

      within %(div[id="workflow-execution-tabs"]) do
        click_on I18n.t('workflow_executions.show.tabs.files')
      end

      assert_text 'FILENAME'

      click_on I18n.t('workflow_executions.show.tabs.params')

      assert_selector 'div.project_name-param > span', text: '--project_name'
      assert_selector 'div.project_name-param > input[value="assembly"]'

      assert_selector 'div.assembler-param > span', text: '--assembler'
      assert_selector 'div.assembler-param > input[value="stub"]'

      assert_selector 'div.random_seed-param > span', text: '--random_seed'
      assert_selector 'div.random_seed-param > input[value="1"]'
    end

    test 'should be able to cancel a workflow' do
      login_as users(:joan_doe)
      workflow_execution = workflow_executions(:workflow_execution_group_shared1)

      visit group_workflow_execution_path(@group, workflow_execution)

      assert_text workflow_execution.id
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")

      click_link I18n.t(:'groups.workflow_executions.show.cancel_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      assert_text workflow_execution.id
      assert_equal workflow_execution.reload.state, 'canceled'
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
    end

    test 'submitter can edit workflow execution post launch from workflow execution page' do
      login_as users(:joan_doe)
      visit group_workflow_execution_path(@group, @workflow_execution_group_shared1)
      dt_value = 'Name'
      new_we_name = 'New Name'

      assert_selector 'h1', text: @workflow_execution_group_shared1.name
      assert_selector 'dt', text: dt_value

      assert_selector 'a', text: I18n.t(:'groups.workflow_executions.show.edit_button'), count: 1
      click_link I18n.t(:'groups.workflow_executions.show.edit_button')

      within('dialog') do
        assert_selector 'h1', text: I18n.t('groups.workflow_executions.edit_dialog.title')
        assert_selector 'p', text: I18n.t('groups.workflow_executions.edit_dialog.description',
                                          workflow_execution_id: @workflow_execution_group_shared1.id)
        assert_selector 'label', text: dt_value
        fill_in placeholder: I18n.t('groups.workflow_executions.edit_dialog.name_placeholder'),
                with: new_we_name

        click_button I18n.t(:'groups.workflow_executions.edit_dialog.submit_button')
      end

      assert_selector 'h1', text: @workflow_execution_group_shared1.name
      assert_selector 'dt', text: dt_value
      assert_selector 'dd', text: new_we_name
    end
  end
end
