# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class WorkflowExecutionsTest < ApplicationSystemTestCase
    WORKFLOW_EXECUTION_COUNT = 12

    setup do
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
      @workflow_execution1 = workflow_executions(:automated_example_completed)
      @workflow_execution2 = workflow_executions(:automated_example_canceled)
      @workflow_execution3 = workflow_executions(:automated_example_running)
      @workflow_execution4 = workflow_executions(:automated_example_new)

      @id_col = '1'
      @name_col = '2'
      @state_col = '3'
      @run_id_col = '4'
      @workflow_name_col = '5'
      @workflow_version_col = '6'
      @created_at_col = '7'

      Flipper.enable(:delete_multiple_workflows)
      Flipper.enable(:attachments_preview)
      Flipper.enable(:cancel_multiple_workflows)
    end

    test 'should display a list of workflow executions' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
    end

    test 'should sort a list of workflow executions' do
      workflow_execution1 = workflow_executions(:automated_workflow_execution)
      workflow_execution3 = workflow_executions(:automated_example_canceling)
      workflow_execution4 = workflow_executions(:automated_workflow_execution_existing)
      workflow_execution_shared1 = workflow_executions(:workflow_execution_shared1)
      workflow_execution_shared2 = workflow_executions(:workflow_execution_shared2)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      click_on I18n.t(:'workflow_executions.table_component.run_id')
      assert_selector "#workflow-executions-table table thead th[aria-sort='ascending']",
                      text: I18n.t(:'workflow_executions.table_component.run_id').upcase

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution4.run_id
        assert_selector "tr:nth-child(#{@run_id_col}) td:nth-child(#{@run_id_col})", text: workflow_execution1.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution_shared2.run_id
      end

      click_on I18n.t(:'workflow_executions.table_component.run_id')
      assert_selector "#workflow-executions-table table thead th[aria-sort='descending']",
                      text: I18n.t(:'workflow_executions.table_component.run_id').upcase

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
        assert_selector "tr:first-child td:nth-child(#{@run_id_col})", text: workflow_execution_shared2.run_id
        assert_selector "tr:nth-child(2) td:nth-child(#{@run_id_col})", text: workflow_execution_shared1.run_id
        assert_selector "tr:last-child td:nth-child(#{@run_id_col})", text: workflow_execution4.run_id
      end

      click_on I18n.t(:'workflow_executions.table_component.workflow_name')
      assert_selector "#workflow-executions-table table thead th[aria-sort='ascending']",
                      text: I18n.t(:'workflow_executions.table_component.workflow_name').upcase

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution2.workflow.name
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution3.workflow.name
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution_shared2.workflow.name
      end

      click_on I18n.t(:'workflow_executions.table_component.workflow_name')
      assert_selector "#workflow-executions-table table thead th[aria-sort='descending']",
                      text: I18n.t(:'workflow_executions.table_component.workflow_name').upcase

      within('#workflow-executions-table table tbody') do
        assert_selector 'tr', count: WORKFLOW_EXECUTION_COUNT
        assert_selector "tr:first-child td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution_shared1.workflow.name
        assert_selector "tr:nth-child(2) td:nth-child(#{@workflow_name_col})",
                        text: workflow_execution_shared2.workflow.name
        assert_selector "tr:last-child td:nth-child(#{@workflow_name_col})",
                        text: @workflow_execution2.workflow.name
      end
    end

    test 'should include workflows that have been shared to the project' do
      workflow_execution1 = workflow_executions(:workflow_execution_shared1)
      workflow_execution2 = workflow_executions(:workflow_execution_shared2)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_selector "tr[id='#{dom_id(workflow_execution1)}']"
      within("tr[id='#{dom_id(workflow_execution1)}'] td:last-child") do
        assert_no_link I18n.t('common.actions.cancel')
        assert_no_link I18n.t('common.actions.delete')
      end

      assert_selector "tr[id='#{dom_id(workflow_execution2)}']"
      within("tr[id='#{dom_id(workflow_execution2)}'] td:last-child") do
        assert_no_link I18n.t('common.actions.cancel')
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'should not include shared workflows that were not shared to that specific project' do
      workflow_execution = workflow_executions(:workflow_execution_shared3)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector '#workflow-executions-table'
      assert_no_selector "tr[id='#{dom_id(workflow_execution)}']"
    end

    test 'should be able to cancel a workflow' do
      workflow_execution = workflow_executions(:automated_example_prepared)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_button 'Cancel', count: 1
        click_button 'Cancel'
      end

      assert_text 'Confirmation required'
      click_button 'Confirm'

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
      workflow_execution = workflow_executions(:automated_example_prepared)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'should not delete a submitted workflow' do
      workflow_execution = workflow_executions(:automated_example_submitted)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'should delete a completed workflow' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

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
      workflow_execution = workflow_executions(:automated_example_error)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

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
      workflow_execution = workflow_executions(:automated_example_canceling)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'should delete a canceled workflow' do
      workflow_execution = workflow_executions(:automated_example_canceled)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

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
      workflow_execution = workflow_executions(:automated_example_running)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'should not delete a new workflow' do
      workflow_execution = workflow_executions(:automated_example_new)

      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      tr = find('a', text: workflow_execution.id).ancestor('tr')

      within tr do
        assert_selector "td:nth-child(#{@state_col})",
                        text: I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
        assert_no_link I18n.t('common.actions.delete')
      end
    end

    test 'can view a workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution_existing)

      visit namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, anchor: 'summary-tab')

      assert_text workflow_execution.id
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_text workflow_execution.workflow.name
      assert_text workflow_execution.metadata['workflow_version']

      within %(nav[id="workflow-executions-tabs"]) do
        click_on I18n.t('workflow_executions.show.tabs.files')
      end

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

    test 'can remove workflow execution from workflow execution page' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')
      assert_selector 'span', text: I18n.t(:'projects.workflow_executions.index.subtitle')

      # Select all workflow executions within the table
      click_button I18n.t('common.controls.select_all')
      within 'tbody' do
        assert_selector 'input[name="workflow_execution_ids[]"]:checked', count: WORKFLOW_EXECUTION_COUNT
      end
      within 'tfoot' do
        assert_selector 'strong[data-selection-target="selected"]', text: WORKFLOW_EXECUTION_COUNT
      end

      visit namespace_project_workflow_execution_path(@namespace, @project, @workflow_execution1, anchor: 'summary-tab')

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

    test 'can filter by ID and name on projects workflow execution index page' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector 'table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within('table tbody') do
        assert_text @workflow_execution1.id
        assert_text @workflow_execution1.name
        assert_text @workflow_execution2.id
        assert_text @workflow_execution2.name
      end

      fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
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

      fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
              with: ''
      find('input.t-search-component').native.send_keys(:return)

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector 'table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      fill_in placeholder: I18n.t(:'shared.workflow_executions.index.search.placeholder'),
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

    test 'analyst or higher access can edit workflow execution post launch from workflow execution page' do
      ### SETUP START ###
      user = users(:james_doe)
      login_as user
      workflow_execution = workflow_executions(:automated_workflow_execution)
      visit namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, anchor: 'summary-tab')
      dt_value = I18n.t('common.labels.name', locale: user.locale)
      new_we_name = 'New Name'
      ### SETUP END ###

      ### VERIFY START ###
      assert_selector 'h1', text: workflow_execution.name

      assert_selector 'dt', exact_text: dt_value
      ### VERIFY END ###

      ### ACTIONS START ###
      assert_selector 'button', text: I18n.t('common.actions.edit', locale: user.locale),
                                count: 1
      click_button I18n.t('common.actions.edit', locale: user.locale)

      within('dialog') do
        assert_selector 'h1', text: I18n.t('projects.workflow_executions.edit_dialog.title', locale: user.locale)
        assert_selector 'p', text: I18n.t('projects.workflow_executions.edit_dialog.description',
                                          workflow_execution_id: workflow_execution.id, locale: user.locale)
        assert_selector 'label', text: dt_value
        fill_in placeholder: I18n.t('projects.workflow_executions.edit_dialog.name_placeholder', locale: user.locale),
                with: new_we_name

        click_button I18n.t(:'projects.workflow_executions.edit_dialog.submit_button', locale: user.locale)
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1', text: workflow_execution.name
      assert_selector 'dt', text: dt_value
      assert_selector 'dd', text: new_we_name
      ### VERIFY END ###
    end

    test 'can view a shared workflow execution that was shared by a different user' do
      workflow_execution = workflow_executions(:workflow_execution_shared2)

      visit namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, anchor: 'summary-tab')

      assert_text workflow_execution.id
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_text workflow_execution.workflow.name
      assert_text workflow_execution.metadata['workflow_version']

      assert_button I18n.t(:'workflow_executions.show.create_export_button')
      assert_no_link I18n.t('common.actions.cancel')
      assert_no_link I18n.t('common.actions.edit')
      assert_no_link I18n.t('common.actions.remove')

      within %(nav[id="workflow-executions-tabs"]) do
        click_on I18n.t('workflow_executions.show.tabs.files')
      end

      attachment = attachments(:workflow_execution_shared_with_project_output_attachment)
      within('table tbody') do
        assert_text attachment.puid
        assert_text attachment.file.filename.to_s
        assert_text I18n.t('components.attachments.table_component.preview')
      end
    end

    test 'can search workflow execution files by puid & filename' do
      Flipper.enable(:workflow_execution_attachments_searching)
      workflow_execution = workflow_executions(:workflow_execution_shared2)

      visit namespace_project_workflow_execution_path(@namespace, @project, workflow_execution, anchor: 'summary-tab')

      assert_text workflow_execution.id
      assert_text I18n.t(:"workflow_executions.state.#{workflow_execution.state}")
      assert_text workflow_execution.workflow.name
      assert_text workflow_execution.metadata['workflow_version']

      within %(nav[id="workflow-executions-tabs"]) do
        click_on I18n.t('workflow_executions.show.tabs.files')
      end

      attachment = attachments(:workflow_execution_shared_with_project_output_attachment)
      within 'tbody' do
        assert_text attachment.puid
        assert_text attachment.file.filename.to_s
        assert_text I18n.t('components.attachments.table_component.preview')
      end

      fill_in placeholder: I18n.t('workflow_executions.files.search.placeholder'), with: attachment.puid
      find('input.t-search-component').native.send_keys(:return)

      within 'tbody' do
        assert_text attachment.puid
        assert_text attachment.file.filename.to_s
        assert_text I18n.t('components.attachments.table_component.preview')
      end

      fill_in placeholder: I18n.t('workflow_executions.files.search.placeholder'), with: attachment.file.filename.to_s
      find('input.t-search-component').native.send_keys(:return)

      within 'tbody' do
        assert_text attachment.puid
        assert_text attachment.file.filename.to_s
        assert_text I18n.t('components.attachments.table_component.preview')
      end
    end

    test 'can successfully delete multiple workflows at once' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within 'table' do
        find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
        find("input[type='checkbox'][value='#{@workflow_execution2.id}']").click
      end

      click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
      click_button I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.description.plural')
                        .gsub! 'COUNT_PLACEHOLDER', '2'
        assert_text ActionController::Base.helpers.strip_tags(
          I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.state_warning_html')
        )
        within('#list_selections') do
          assert_text "ID: #{@workflow_execution1.id}"
          assert_text "ID: #{@workflow_execution2.id}"
        end
        click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
      end

      assert_no_selector '#dialog'

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT - 2} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT - 2
      assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.success')
    end

    test 'can partially delete multiple workflows at once' do
      # attempt to destroy deletable and non-deletable workflows
      new_workflow = workflow_executions(:automated_example_new)
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within 'table' do
        find("input[type='checkbox'][value='#{new_workflow.id}']").click
        find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
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
          assert_text "ID: #{new_workflow.id}"
          assert_text "ID: #{@workflow_execution1.id}"
          assert_text "ID: #{@workflow_execution2.id}"
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
      new_workflow = workflow_executions(:automated_example_new)
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within 'table' do
        find("input[type='checkbox'][value='#{new_workflow.id}']").click
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
          assert_text "ID: #{new_workflow.id}"
        end
        click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
      end

      assert_no_selector '#dialog'

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
      assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.error')
    end

    test 'can successfully cancel multiple workflows at once' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within 'table' do
        find("input[type='checkbox'][value='#{@workflow_execution3.id}']").click
        find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
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
          assert_text "ID: #{@workflow_execution3.id}"
          assert_text "ID: #{@workflow_execution4.id}"
        end
        click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
      end

      assert_no_selector '#dialog'

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
      assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.success')
    end

    test 'can partially cancel multiple workflows at once' do
      # attempt to cancel cancellable and non-cancellable workflows
      visit namespace_project_workflow_executions_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      within 'table' do
        find("input[type='checkbox'][value='#{@workflow_execution1.id}']").click
        find("input[type='checkbox'][value='#{@workflow_execution3.id}']").click
        find("input[type='checkbox'][value='#{@workflow_execution4.id}']").click
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
          assert_text "ID: #{@workflow_execution3.id}"
          assert_text "ID: #{@workflow_execution4.id}"
        end
        click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
      end

      assert_no_selector '#dialog'

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT
      assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.partial_error', unsuccessful: '1/3')
      assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.partial_success', successful: '2/3')
    end

    test 'cannot cancel non-cancellable workflows' do
      visit namespace_project_workflow_executions_path(@namespace, @project)

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

    test 'user with access level >= Maintainer can view cancel and delete workflows buttons' do
      visit namespace_project_workflow_executions_path(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      assert_text "Displaying #{WORKFLOW_EXECUTION_COUNT} items"
      assert_selector '#workflow-executions-table table tbody tr', count: WORKFLOW_EXECUTION_COUNT

      click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
      assert_selector 'button',
                      text: I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')
      assert_selector 'button',
                      text: I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')
    end

    test 'user with access level Analyst cannot view cancel and delete workflows buttons' do
      namespace = namespaces_project_namespaces(:project1_namespace)
      project = projects(:project1)
      login_as users(:james_doe)
      visit namespace_project_workflow_executions_path(namespace, project)
      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
      assert_no_selector 'button',
                         text: I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')
      assert_no_selector 'button',
                         text: I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')
    end
  end
end
