# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class AutomatedWorkflowExecutionsTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
    end

    test 'can see a table listing of automated workflow executions for a project' do
      visit namespace_project_automated_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      assert_selector 'tr', count: 3 + header_row_count
    end

    test 'can see an empty state for table listing of automated workflow executions for a project' do
      project = projects(:project2)
      visit namespace_project_automated_workflow_executions_path(@namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'projects.automated_workflow_executions.table.empty.title')
        assert_text I18n.t(:'projects.automated_workflow_executions.table.empty.description')
      end
    end

    test 'can create a new automated workflow execution for a project' do
      project = projects(:project2)
      visit namespace_project_automated_workflow_executions_path(@namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      assert_selector(
        'a',
        text: I18n.t(:'projects.automated_workflow_executions.index.add_new_automated_workflow_execution'), count: 1
      )

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'projects.automated_workflow_executions.table.empty.title')
        assert_text I18n.t(:'projects.automated_workflow_executions.table.empty.description')
      end

      click_link I18n.t(:'projects.automated_workflow_executions.index.add_new_automated_workflow_execution')

      within('dialog') do
        assert_selector '.dialog--header',
                        text: I18n.t(:'projects.automated_workflow_executions.pipeline_selection_modal.title')
        assert_link text: 'phac-nml/iridanextexample', count: 1
        click 'phac-nml/iridanextexample'
      end

      within('dialog[open].dialog--size-xl') do
        assert_text I18n.t(:'components.nextflow.update_samples')
        assert_text I18n.t(:'components.nextflow.email_notification')

        assert_button I18n.t(:'workflow_executions.submissions.create.submit')
        click_button I18n.t(:'workflow_executions.submissions.create.submit')
      end

      assert_selector 'tr', count: 1 + header_row_count
    end

    test 'can delete an automated workflow execution for a project' do
      visit namespace_project_automated_workflow_executions_path(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      within('table tbody tr:first-child') do
        click_link I18n.t(:'projects.automated_workflow_executions.actions.delete_button')
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'projects.automated_workflow_executions.destroy.success',
                         workflow_name: 'phac-nml/iridanextexample')
    end

    test 'can edit an automated workflow execution for a project' do
      visit namespace_project_automated_workflow_executions_path(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.automated_workflow_executions.index.title')
      assert_selector 'p', text: I18n.t(:'projects.automated_workflow_executions.index.subtitle')

      within('table tbody tr:first-child') do
        click_link I18n.t(:'projects.automated_workflow_executions.actions.edit_button')
      end

      within('dialog[open].dialog--size-xl') do
        assert_accessible
        # update input[name="workflow_execution[name]"] with the value 'Updated Name'
        fill_in 'workflow_execution[name]', with: 'Updated Name'
        click_button I18n.t(:'workflow_executions.submissions.create.update')
      end

      assert_no_selector 'dialog[open]'

      # check the first item in the table for the new name
      within('table tbody tr:first-child') do
        assert_text 'Updated Name'
      end
    end

    test 'hidden edit button when automated workflow execution is disabled' do
      disabled_automated_pipeline = automated_workflow_executions(:disabled_automated_workflow_execution)
      visit namespace_project_automated_workflow_executions_path(@namespace, @project)
      within('tbody') do
        assert_selector "tr[id='#{dom_id(disabled_automated_pipeline)}'] th:first-child",
                        text: disabled_automated_pipeline.id

        within("tr[id='#{dom_id(disabled_automated_pipeline)}'] td:last-child") do
          assert_text I18n.t('projects.automated_workflow_executions.actions.delete_button')
          assert_no_text I18n.t('projects.automated_workflow_executions.actions.edit_button')
        end
      end
    end
  end
end
