# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class WorkflowExecutionsTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
      @workflow_execution1 = workflow_executions(:automated_example_completed)
      @workflow_execution2 = workflow_executions(:automated_example_canceled)

      @id_col = '1'
      @name_col = '2'
      @state_col = '3'
      @run_id_col = '4'
      @workflow_name_col = '5'
      @workflow_version_col = '6'
      @created_at_col = '7'
    end

    test 'should display a list of workflow executions' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      assert_selector '#workflow_executions_table table tbody tr', count: 10
    end

    test 'should sort a list of workflow executions' do
      workflow_execution1 = workflow_executions(:automated_workflow_execution)
      workflow_execution3 = workflow_executions(:automated_example_canceling)
      workflow_execution4 = workflow_executions(:automated_workflow_execution_existing)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      click_on 'Run ID'
      assert_selector "#workflow_executions_table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_up"

      within('#workflow_executions_table table tbody') do
        assert_selector 'tr', count: 10
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution4.run_id
        assert_selector "tr:nth-child(#{@run_id_col}) td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: @workflow_execution2.run_id
      end

      click_on 'Run ID'
      assert_selector "#workflow_executions_table table thead th:nth-child(#{@run_id_col}) svg.icon-arrow_down"

      within('#workflow_executions_table table tbody') do
        assert_selector 'tr', count: 10
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: @workflow_execution2.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: workflow_execution3.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution4.run_id
      end

      click_on 'Workflow Name'
      assert_selector "#workflow_executions_table table thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_up"

      within('#workflow_executions_table table tbody') do
        assert_selector 'tr', count: 10
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution2.metadata['workflow_name']
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution3.metadata['workflow_name']
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution4.metadata['workflow_name']
      end

      click_on 'Workflow Name'
      assert_selector "#workflow_executions_table table thead th:nth-child(#{@workflow_name_col}) svg.icon-arrow_down"

      within('#workflow_executions_table table tbody') do
        assert_selector 'tr', count: 10
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution4.metadata['workflow_name']
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution1.metadata['workflow_name']
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution2.metadata['workflow_name']
      end
    end

    test 'should be able to cancel a workflow' do
      workflow_execution = workflow_executions(:automated_example_prepared)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

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
          :'concerns.workflow_execution_actions.cancel.success',
          workflow_name: workflow_execution.metadata['workflow_name']
        )
      end

      assert_selector "tbody tr td:nth-child(#{@state_col})", text: 'Canceling'
      assert_no_selector "tbody tr td:nth-child(#{@state_col}) a[text='Cancel']"
    end

    test 'should not delete a prepared workflow' do
      workflow_execution = workflow_executions(:automated_example_prepared)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link 'Delete'
      end
    end

    test 'should not delete a submitted workflow' do
      workflow_execution = workflow_executions(:automated_example_submitted)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link 'Delete'
      end
    end

    test 'should delete a completed workflow' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: @workflow_execution1.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{@workflow_execution1.state}")
        assert_link 'Delete', count: 1
        click_link 'Delete'
      end

      assert_text 'Confirmation required'
      click_button 'Confirm'

      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(
          :'concerns.workflow_execution_actions.destroy.success',
          workflow_name: @workflow_execution1.metadata['workflow_name']
        )
      end

      assert_no_text @workflow_execution1.id
    end

    test 'should delete an errored workflow' do
      workflow_execution = workflow_executions(:automated_example_error)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

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
      workflow_execution = workflow_executions(:automated_example_canceling)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link 'Delete'
      end
    end

    test 'should delete a canceled workflow' do
      workflow_execution = workflow_executions(:automated_example_canceled)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

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
      workflow_execution = workflow_executions(:automated_example_running)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link 'Delete'
      end
    end

    test 'should not delete a new workflow' do
      workflow_execution = workflow_executions(:automated_example_new)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link 'Delete'
      end
    end

    test 'can view a workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution_existing)

      visit namespace_project_workflow_execution_path(@namespace, @project, workflow_execution)

      assert_text workflow_execution.id
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_text workflow_execution.metadata['workflow_name']
      assert_text workflow_execution.metadata['workflow_version']

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

    test 'can remove workflow execution from workflow execution page' do
      visit namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution1)

      click_link I18n.t(:'projects.workflow_executions.show.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      within %(#workflow_executions_table table tbody) do
        assert_selector 'tr', count: 9
        assert_no_text @workflow_execution1.id
      end
    end

    test 'can filter by ID and name on projects workflow execution index page' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_text 'Displaying 1-10 of 10 items'
      assert_selector 'table tbody tr', count: 10

      within('table tbody') do
        assert_text @workflow_execution1.id
        assert_text @workflow_execution1.name
        assert_text @workflow_execution2.id
        assert_text @workflow_execution2.name
      end

      fill_in placeholder: I18n.t(:'workflow_executions.index.search.placeholder'),
              with: @workflow_execution1.id
      find('input.t-search-component').native.send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_text @workflow_execution1.id
        assert_text @workflow_execution1.name
        assert_no_text @workflow_execution2.id
        assert_no_text @workflow_execution2.name
      end

      fill_in placeholder: I18n.t(:'workflow_executions.index.search.placeholder'),
              with: ''
      find('input.t-search-component').native.send_keys(:return)

      assert_text 'Displaying 1-10 of 10 items'
      assert_selector 'table tbody tr', count: 10

      fill_in placeholder: I18n.t(:'workflow_executions.index.search.placeholder'),
              with: @workflow_execution2.name
      find('input.t-search-component').native.send_keys(:return)

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1

      within('table tbody') do
        assert_no_text @workflow_execution1.id
        assert_no_text @workflow_execution1.name
        assert_text @workflow_execution2.id
        assert_text @workflow_execution2.name
      end
    end

    test 'empty state' do
      project = projects(:project2)
      visit namespace_project_workflow_executions_path(@namespace, project)

      assert_no_selector 'div#workflow_executions_table'
      assert_no_selector 'table'

      assert_text I18n.t('viral.data_table_component.empty.workflow_executions.title')
      assert_text I18n.t('viral.data_table_component.empty.workflow_executions.description')
    end

    test 'empty filter state' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_text 'Displaying 1-10 of 10 items'
      assert_selector 'table tbody tr', count: 10

      assert_selector 'div#workflow_executions_table'
      assert_selector 'table'

      fill_in placeholder: I18n.t(:'workflow_executions.index.search.placeholder'),
              with: 'search that results in no entries'
      find('input.t-search-component').native.send_keys(:return)

      assert_text I18n.t('components.viral.pagy.empty_state.title')
      assert_text I18n.t('components.viral.pagy.empty_state.description')
    end
  end
end
