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
    end

    test 'should display a list of workflow executions' do
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'groups.workflow_executions.index.subtitle')

      assert_selector '#workflow-executions-table table tbody tr', count: 3
    end

    test 'should sort a list of workflow executions' do
      visit group_workflow_executions_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'groups.workflow_executions.index.subtitle')

      click_on 'Run ID'
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_up"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 3
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared1.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared2.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared3.run_id
      end

      click_on 'Run ID'
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_down"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 3
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared3.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared2.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: @workflow_execution_group_shared1.run_id
      end

      click_on I18n.t(:'workflow_executions.table_component.workflow_name')
      assert_selector "#workflow-executions-table table thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_up"

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: 3
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
        assert_selector 'tr', count: 3
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared1.metadata['workflow_name']
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared2.metadata['workflow_name']
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution_group_shared3.metadata['workflow_name']
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
    end
  end
end
