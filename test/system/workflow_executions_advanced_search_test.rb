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
        find("input[name$='[value]']").fill_in with: 'completed'
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
          find("input[name$='[value]']").fill_in with: 'completed'
        end

        # Set second condition
        within all("fieldset[data-advanced-search-target='conditionsContainer']")[1] do
          find("select[name$='[field]']").find("option[value='id']").select_option
          find("select[name$='[operator]']").find("option[value='>=']").select_option
          find("input[name$='[value]']").fill_in with: '1'
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
          find("input[name$='[value]']").fill_in with: 'completed'
        end
      end

      # Set second group condition
      within all("fieldset[data-advanced-search-target='groupsContainer']")[1] do
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          find("select[name$='[field]']").find("option[value='state']").select_option
          find("select[name$='[operator]']").find("option[value='=']").select_option
          find("input[name$='[value]']").fill_in with: 'running'
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
        find("input[name$='[value]']").fill_in with: 'completed'
      end

      # Clear filters
      click_button I18n.t('components.advanced_search_component.clear_filter_button')

      # Verify form is reset
      assert_selector "fieldset[data-advanced-search-target='groupsContainer']", count: 1
      within first("fieldset[data-advanced-search-target='groupsContainer']") do
        assert_selector "fieldset[data-advanced-search-target='conditionsContainer']", count: 1
        within first("fieldset[data-advanced-search-target='conditionsContainer']") do
          assert_equal '', find("select[name$='[field]']").value
          assert_equal '', find("select[name$='[operator]']").value
          assert_equal '', find("input[name$='[value]']").value
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

      # Dialog should still be open
      assert_selector 'dialog[open]'
    end
  end

  test 'can filter by workflow_name JSONB field' do
    visit workflow_executions_path

    click_button I18n.t('components.advanced_search_component.title')

    within 'dialog[open]' do
      within first("fieldset[data-advanced-search-target='conditionsContainer']") do
        # Select workflow_name from metadata fields optgroup
        find("select[name$='[field]']").find("option[value='workflow_name']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        find("input[name$='[value]']").fill_in with: 'phac-nml/iridanextexample'
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
        find("select[name$='[field]']").find("option[value='workflow_version']").select_option
        find("select[name$='[operator]']").find("option[value='=']").select_option
        find("input[name$='[value]']").fill_in with: '1.0.0'
      end

      click_button I18n.t('components.advanced_search_component.apply_filter_button')
    end

    assert_no_selector 'dialog[open]'
    assert_selector '#workflow-executions-table table tbody tr'
  end
end
