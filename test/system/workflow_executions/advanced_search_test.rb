# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class AdvancedSearchTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user

      @workflow_execution1 = workflow_executions(:irida_next_example_completed)
      @workflow_execution2 = workflow_executions(:irida_next_example_running)
      @workflow_execution3 = workflow_executions(:irida_next_example_error)
    end

    test 'advanced search shows state dropdown with translated values' do
      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Verify accessibility
        assert_accessible

        # Select state field
        within first("fieldset[data-advanced-search-target='conditionsContainer']", visible: :visible) do
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='state']", text: I18n.t('workflow_executions.table_component.state'))
            .select_option

          # Wait for operator dropdown to update with enum operators
          operator_select = find("select[name$='[operator]']", visible: :visible)
          # Wait until the '=' option is available (enum-specific operators)
          assert_selector "select[name$='[operator]'] option[value='=']", wait: 5, visible: :visible

          # Select equals operator
          operator_select.find("option[value='=']").select_option

          # Wait for JavaScript to update the value field
          sleep 1

          # Verify that a select dropdown appears for state value (not text input)
          assert_selector "select[name$='[value]']", count: 1, visible: :visible, wait: 5
          assert_no_selector "input[type='text'][name$='[value]']", visible: :visible

          %w[
            initial prepared submitted running completing completed error canceling canceled
          ].each do |state|
            assert_selector(
              "select[name$='[value]'] option[value='#{state}']",
              text: I18n.t("workflow_executions.state.#{state}"),
              visible: :visible,
              wait: 5
            )
          end

          # Select completed state
          find(
            "select[name$='[value]'] option[value='completed']",
            text: I18n.t('workflow_executions.state.completed'),
            visible: :visible
          ).select_option
        end

        # Apply filter
        click_button I18n.t('components.advanced_search_component.apply_filter_button')
      end

      # Verify search results show only completed workflows
      # This assertion will depend on your fixture data
      # Adjust based on actual workflow execution fixtures
      within 'table' do
        assert_text @workflow_execution1.name if @workflow_execution1.completed?
        assert_no_text @workflow_execution2.name if @workflow_execution2.running?
      end
    end

    test 'advanced search with in operator shows multiselect for state' do
      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Verify accessibility
        assert_accessible

        # Select state field
        within first("fieldset[data-advanced-search-target='conditionsContainer']", visible: :visible) do
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='state']", text: I18n.t('workflow_executions.table_component.state'))
            .select_option

          # Wait for operator dropdown to update with enum operators
          assert_selector "select[name$='[operator]'] option[value='in']", wait: 5, visible: :visible

          # Select 'in' operator
          find("select[name$='[operator]']", visible: :visible).find("option[value='in']").select_option

          # Verify that a multi-select dropdown appears
          assert_selector "select[name$='[value][]'][multiple='multiple']", count: 1, visible: :visible, wait: 5

          # Verify translated state options are available
          assert_selector(
            "select[name$='[value][]'][multiple='multiple'] option[value='completed']",
            text: I18n.t('workflow_executions.state.completed'),
            visible: :visible,
            wait: 5
          )
          assert_selector(
            "select[name$='[value][]'][multiple='multiple'] option[value='error']",
            text: I18n.t('workflow_executions.state.error'),
            visible: :visible,
            wait: 5
          )
        end
      end
    end

    test 'advanced search with non-enum field shows text input' do
      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Verify accessibility
        assert_accessible

        # Select name field (non-enum)
        within first("fieldset[data-advanced-search-target='conditionsContainer']", visible: :visible) do
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='name']", text: I18n.t('workflow_executions.table_component.name'))
            .select_option

          # Select equals operator
          find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

          # Verify that a text input appears (not select dropdown)
          assert_selector "input[type='text'][name$='[value]']", count: 1, visible: :visible, wait: 5
          assert_no_selector "select[name$='[value]']", visible: :visible
        end
      end
    end

    test 'can search workflow executions by state using dropdown' do
      # Create test workflow executions with known states
      namespace = namespaces_project_namespaces(:project1_namespace)
      completed_we = WorkflowExecution.create!(
        name: 'Completed Search Test',
        submitter: @user,
        namespace:,
        state: :completed,
        metadata: { pipeline_id: 'test', workflow_version: '1.0' }
      )
      error_we = WorkflowExecution.create!(
        name: 'Error Search Test',
        submitter: @user,
        namespace:,
        state: :error,
        metadata: { pipeline_id: 'test', workflow_version: '1.0' }
      )

      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Configure search for completed state
        within first("fieldset[data-advanced-search-target='conditionsContainer']", visible: :visible) do
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='state']", text: I18n.t('workflow_executions.table_component.state'))
            .select_option

          # Wait for operator dropdown to update with enum operators
          assert_selector "select[name$='[operator]'] option[value='=']", wait: 5, visible: :visible

          find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option
          find(
            "select[name$='[value]'] option[value='completed']",
            text: I18n.t('workflow_executions.state.completed'),
            visible: :visible
          ).select_option
        end

        # Apply filter
        click_button I18n.t('components.advanced_search_component.apply_filter_button')
      end

      # Verify results show only completed workflows
      within 'table' do
        assert_text completed_we.name
        assert_no_text error_we.name
      end
    end

    test 'changing field resets operator and value' do
      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Select state field
        within first("fieldset[data-advanced-search-target='conditionsContainer']", visible: :visible) do
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='state']", text: I18n.t('workflow_executions.table_component.state'))
            .select_option

          # Select equals operator
          find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

          # Select completed state
          find(
            "select[name$='[value]'] option[value='completed']",
            text: I18n.t('workflow_executions.state.completed'),
            visible: :visible
          ).select_option

          # Change field to name
          find("select[name$='[field]']", visible: :visible)
            .find("option[value='name']", text: I18n.t('workflow_executions.table_component.name'))
            .select_option

          # Verify operator is reset to blank
          assert_equal '', find("select[name$='[operator]']", visible: :visible).value

          # Verify value input is hidden/cleared
          assert_selector '.value.invisible', visible: :all
        end
      end
    end
  end
end
