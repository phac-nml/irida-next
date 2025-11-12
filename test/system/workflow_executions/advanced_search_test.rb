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
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option

          # Wait for operator dropdown to update with enum operators
          operator_select = find("select[name$='[operator]']")
          # Wait until the '=' option is available (enum-specific operators)
          assert_selector "select[name$='[operator]'] option[value='=']", wait: 5

          # Select equals operator
          operator_select.find("option[value='=']").select_option

          # Verify that a select dropdown appears for state value (not text input)
          assert_selector "select[name$='[value]']", count: 1
          assert_no_selector "input[type='text'][name$='[value]']"

          # Verify all state options are present with translated labels
          within "select[name$='[value]']" do
            assert_text I18n.t('workflow_executions.state.initial')
            assert_text I18n.t('workflow_executions.state.prepared')
            assert_text I18n.t('workflow_executions.state.submitted')
            assert_text I18n.t('workflow_executions.state.running')
            assert_text I18n.t('workflow_executions.state.completing')
            assert_text I18n.t('workflow_executions.state.completed')
            assert_text I18n.t('workflow_executions.state.error')
            assert_text I18n.t('workflow_executions.state.canceling')
            assert_text I18n.t('workflow_executions.state.canceled')
          end

          # Select completed state
          find("select[name$='[value]']").find(
            "option[value='completed']",
            text: I18n.t('workflow_executions.state.completed')
          ).select_option
        end

        # Apply filter
        click_button I18n.t('components.advanced_search_component.apply_filter_button')
      end

      # Verify search results show only completed workflows
      # This assertion will depend on your fixture data
      # Adjust based on actual workflow execution fixtures
      within 'table' do
        if @workflow_execution1.completed?
          assert_text @workflow_execution1.name
        end
        if @workflow_execution2.running?
          assert_no_text @workflow_execution2.name
        end
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
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option

          # Wait for operator dropdown to update with enum operators
          assert_selector "select[name$='[operator]'] option[value='in']", wait: 5

          # Select 'in' operator
          find("select[name$='[operator]']").find("option[value='in']").select_option

          # Verify that a multi-select dropdown appears
          assert_selector "select[name$='[value]'][multiple='multiple']", count: 1

          # Verify translated state options are available
          within "select[name$='[value]'][multiple='multiple']" do
            assert_text I18n.t('workflow_executions.state.completed')
            assert_text I18n.t('workflow_executions.state.error')
          end
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
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='name']").select_option

          # Select equals operator
          find("select[name$='[operator]']").find("option[value='=']").select_option

          # Verify that a text input appears (not select dropdown)
          assert_selector "input[type='text'][name$='[value]']", count: 1
          assert_no_selector "select[name$='[value]']"
        end
      end
    end

    test 'can search workflow executions by state using dropdown' do
      # Create test workflow executions with known states
      namespace = @user.namespace
      completed_we = WorkflowExecution.create!(
        name: 'Completed Search Test',
        submitter: @user,
        namespace: namespace,
        state: :completed,
        metadata: { pipeline_id: 'test', workflow_version: '1.0' }
      )
      error_we = WorkflowExecution.create!(
        name: 'Error Search Test',
        submitter: @user,
        namespace: namespace,
        state: :error,
        metadata: { pipeline_id: 'test', workflow_version: '1.0' }
      )

      visit workflow_executions_url

      # Open advanced search dialog
      click_button I18n.t('components.advanced_search_component.title')

      within 'dialog' do
        # Configure search for completed state
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option

          # Wait for operator dropdown to update with enum operators
          assert_selector "select[name$='[operator]'] option[value='=']", wait: 5

          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("select[name$='[value]']").find(
            "option[value='completed']",
            text: I18n.t('workflow_executions.state.completed')
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
  end
end
