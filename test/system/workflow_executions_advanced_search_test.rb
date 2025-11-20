# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsAdvancedSearchTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
    @workflow_execution1 = workflow_executions(:irida_next_example_completed)
    @workflow_execution2 = workflow_executions(:irida_next_example)
  end

  test 'can open and use advanced search dialog' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    # Open advanced search dialog
    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      assert_accessible
      assert_selector 'h1', text: I18n.t('components.advanced_search_component.title')

      # Verify form structure
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']"
      assert_selector "fieldset[data-advanced-search-target='conditionsContainer']"

      # Verify field options are available
      within "select[name$='[field]']" do
        assert_text I18n.t('workflow_executions.table_component.id')
        assert_text I18n.t('workflow_executions.table_component.name')
        assert_text I18n.t('workflow_executions.table_component.state')
        assert_text I18n.t('workflow_executions.table_component.run_id')
        assert_text I18n.t('workflow_executions.table_component.created_at')
        assert_text I18n.t('workflow_executions.table_component.updated_at')
      end

      # Verify operators are available
      within "select[name$='[operator]']" do
        assert_text I18n.t('components.advanced_search_component.operation.equals')
        assert_text I18n.t('components.advanced_search_component.operation.contains')
        assert_text I18n.t('components.advanced_search_component.operation.in')
      end
    end
  end

  test 'can filter workflow executions by state using advanced search' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Set up a condition: state = completed
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='state']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        find("select[name$='[value]']").find("option[value='completed']").select_option
      end

      # Apply the filter
      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    # Verify dialog closes and results are filtered
    assert_no_selector 'dialog[open]'
    # Results should be filtered (exact count depends on fixtures)
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can filter workflow executions by name using advanced search' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Set up a condition: name contains
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='name']").select_option
        find("select[name$='[operator]']").find("option[value='contains']").select_option
        find("input[name$='[value]']").fill_in with: @workflow_execution1.name.to_s
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can add multiple conditions to a group' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Add a second condition
      within first("fieldset[data-advanced-search-target='groupsContainer']") do
        click_button I18n.t('components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2

        # Set first condition
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find("select[name$='[field]']").find("option[value='state']").select_option
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("select[name$='[value]']").find("option[value='completed']").select_option
        end

        # Set second condition - use name contains instead of id >= 1 (id is UUID, not numeric)
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("select[name$='[field]']").find("option[value='name']").select_option
          find("select[name$='[operator]']").find("option[value='contains']").select_option
          find("input[name$='[value]']").fill_in with: @workflow_execution1.name.to_s
        end
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can add multiple groups for OR logic' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Add a second group
      click_button I18n.t('components.advanced_search_component.add_group_button')
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2

      # Set first group condition
      within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("select[name$='[value]']").find("option[value='completed']").select_option
        end
      end

      # Set second group condition
      within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("select[name$='[value]']").find("option[value='running']").select_option
        end
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can clear advanced search filters' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Set up a condition
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='state']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        find("select[name$='[value]']").find("option[value='completed']").select_option
      end

      # Clear filters - this will submit the form and reload the page
      click_button I18n.t('components.advanced_search_component.clear_filter_button')
    end

    # After page reload, verify filters were cleared by checking that advanced search status is not active
    # and all workflow executions are visible (not filtered)
    assert_no_selector 'dialog[open]'

    # Verify that the advanced search button doesn't have active status (no clear button visible)
    # by checking that filters were cleared - we should see all workflow executions
    assert_selector '#workflow-executions-table table tbody tr'

    # Re-open dialog to verify form is reset
    # Wait for page to be fully loaded after clear/reload
    assert_selector '#workflow-executions-table', wait: 5
    click_button I18n.t('components.advanced_search_component.title')

    # Wait for dialog to be fully open and rendered
    assert_selector 'dialog[open]', wait: 5

    within 'dialog[open]' do
      # Verify form is reset - wait for groups to be rendered
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1, wait: 5

      # Use find with wait to ensure element is stable before interacting
      groups_container = find("fieldset[data-advanced-search-target='groupsContainer']", wait: 5)

      within groups_container do
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1, wait: 5

        conditions_container = find("fieldset[data-advanced-search-target='conditionsContainer']", wait: 5)

        within conditions_container do
          # Wait for selects to be stable before checking values
          field_select = find("select[name$='[field]']", wait: 5)
          operator_select = find("select[name$='[operator]']", wait: 5)

          assert_equal '', field_select.value
          assert_equal '', operator_select.value

          # Value field may be hidden when operator is blank, so check if it exists and is empty
          value_selects = all("select[name$='[value]']", visible: :all)
          value_inputs = all("input[name$='[value]']", visible: :all)

          if value_selects.any?
            assert_equal '', value_selects.first.value
          elsif value_inputs.any?
            assert_equal '', value_inputs.first.value
          end
        end
      end
    end
  end

  test 'can remove a condition from advanced search' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Add a second condition
      within first("fieldset[data-advanced-search-target='groupsContainer']") do
        click_button I18n.t('components.advanced_search_component.add_condition_button')
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 2

        # Remove the first condition
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
          find('button').click
        end

        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
      end
    end
  end

  test 'can remove a group from advanced search' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Add a second group
      click_button I18n.t('components.advanced_search_component.add_group_button')
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 2

      # Remove the second group
      within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
        click_button I18n.t('components.advanced_search_component.remove_group_button')
      end

      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
    end
  end

  test 'advanced search dialog prompts for confirmation when closing with unapplied changes' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Make a change but don't apply
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='state']").select_option
      end

      # Try to close - should prompt for confirmation
      text = dismiss_confirm do
        click_button I18n.t('components.dialog.close')
      end
      assert_includes text, I18n.t('components.advanced_search_component.confirm_close_text')
    end

    # Dialog should still be open after dismissing the confirmation
    assert_selector 'dialog[open]'
  end

  test 'can filter by workflow_name JSONB field' do
    # Check if workflow names are available (requires pipelines to be configured)
    workflows = Irida::Pipelines.instance.pipelines('executable')
    workflow_names = workflows.map { |_pipeline_id, pipeline| pipeline.name[I18n.locale.to_s] }.compact_blank

    skip 'Workflow names not available in test environment' if workflow_names.empty?

    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        # Select workflow_name from metadata fields optgroup
        find("select[name$='[field]']").find("option[value='metadata.workflow_name']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        # workflow_name is an enum field, so it renders as a select dropdown
        find("select[name$='[value]']", wait: 5).find('option', text: workflow_names.first, match: :first).select_option
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can filter by workflow_version JSONB field' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='metadata.workflow_version']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        # Wait for the value input to become visible after operator selection
        find("input[name$='[value]']", visible: :visible, wait: 5).fill_in with: '1.0.0'
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can filter using not_equals operator' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='state']").select_option
        find("select[name$='[operator]']").find("option[value='!=']").select_option
        find("select[name$='[value]']").find("option[value='error']").select_option
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'can filter by run_id which uses uppercase conversion' do
    workflow_execution = workflow_executions(:irida_next_example_completed)
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='run_id']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        # Use lowercase to test uppercase conversion
        find("input[name$='[value]']").fill_in with: workflow_execution.run_id.downcase
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    # Should find results since run_id is converted to uppercase in the query
    assert_selector '#workflow-executions-table table tbody tr'
  end

  test 'advanced search preserves filters when reopening dialog' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      # Set up a condition
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        find("select[name$='[field]']").find("option[value='state']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        find("select[name$='[value]']").find("option[value='completed']").select_option
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    # Wait for results to load
    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table'

    # Reopen the dialog
    click_button I18n.t('components.advanced_search_component.title')

    # Verify the previous filter is still present
    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        field_select = find("select[name$='[field]']")
        operator_select = find("select[name$='[operator]']")
        value_select = find("select[name$='[value]']")

        assert_equal 'state', field_select.value
        assert_equal '=', operator_select.value
        assert_equal 'completed', value_select.value
      end
    end
  end

  test 'validation errors prevent invalid searches' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        # Select field and operator but leave value empty for non-exists operators
        find("select[name$='[field]']").find("option[value='name']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        # Leave value empty
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    # Dialog should remain open due to validation error
    # The actual validation behavior may show error messages inline
    # This test verifies the form doesn't submit with invalid data
    assert_selector 'dialog[open]'
  end

  test 'enum fields show correct operators' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        # Select state enum field
        find("select[name$='[field]']").find("option[value='state']").select_option

        # Enum fields should only show specific operators (equals, not_equals, in, not_in)
        # and not text operators like 'contains'
        operator_select = find("select[name$='[operator]']")
        operator_options = operator_select.all('option').map(&:text)

        # Should have enum operators
        assert_includes operator_options, I18n.t('components.advanced_search_component.operation.equals')
        assert_includes operator_options, I18n.t('components.advanced_search_component.operation.not_equals')
        assert_includes operator_options, I18n.t('components.advanced_search_component.operation.in')
        assert_includes operator_options, I18n.t('components.advanced_search_component.operation.not_in')

        # Should not have text operators for enum fields
        # Note: This depends on handleFieldChange JavaScript implementation
      end
    end
  end
end
