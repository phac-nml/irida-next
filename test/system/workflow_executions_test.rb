# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsTest < ApplicationSystemTestCase
  PAGE_SIZE = 20

  setup do
    login_as users(:john_doe)
  end

  test 'tab clicks lazy-load tab content without full-page navigation' do
    workflow_execution = workflow_executions(:workflow_execution_existing)

    visit workflow_execution_path(workflow_execution)

    assert_current_path workflow_execution_path(workflow_execution)

    click_on I18n.t('workflow_executions.show.tabs.params')

    assert_current_path workflow_execution_path(workflow_execution), ignore_query: false
    assert_selector 'div.project_name-param > span', text: '--project_name'
    assert_selector 'div.assembler-param > span', text: '--assembler'

    click_on I18n.t('workflow_executions.show.tabs.files')

    assert_current_path workflow_execution_path(workflow_execution), ignore_query: false
    assert_text I18n.t('workflow_executions.files.empty.title')
  end

  test 'advanced-search dialog supports apply and clear lifecycle on workflow listing' do
    visit workflow_executions_path

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    within('dialog') do
      select_state_advanced_search_field
      find("select[name$='[operator]']", visible: :visible).find("option[value='=']").select_option

      if has_selector?("select[name$='[value]']", visible: :visible)
        find("select[name$='[value]']", visible: :visible).select(I18n.t('workflow_executions.state.completed'))
      else
        find("input[name$='[value]']", visible: :visible).fill_in with: 'completed'
      end

      click_button I18n.t(:'components.advanced_search_component.v1.apply_filter_button')
    end

    assert_no_selector 'dialog[open] h1', text: I18n.t(:'components.advanced_search_component.v1.title')
    assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.v1.clear_aria_label')}']"

    click_button I18n.t(:'components.advanced_search_component.v1.title')

    within('dialog') do
      click_button I18n.t(:'components.advanced_search_component.v1.clear_filter_button')
    end

    assert_no_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.v1.clear_aria_label')}']"
  end

  test 'select page checkbox exposes mixed and all-selected accessibility state' do
    visit workflow_executions_path

    first_row_checkbox = find("input[name='workflow_execution_ids[]']", match: :first, visible: :all)
    first_row_checkbox.click

    select_page = find('input#select-page', visible: :all)
    assert_not select_page.checked?
    assert_equal false, page.evaluate_script("document.querySelector('#select-page').indeterminate")
    assert_equal 'select-page-status', select_page[:'aria-describedby']

    within '#select-page-status' do
      assert_text I18n.t('components.workflow_executions.table_component.select_page_state.some',
                         selected: 1,
                         total: PAGE_SIZE)
    end

    select_page.click

    select_page = find('input#select-page', visible: :all)
    assert select_page.checked?
    assert_nil select_page[:'aria-describedby']
  end

  test 'bulk delete submits selected workflows through the confirmation dialog' do
    selected_workflows = [
      workflow_executions(:irida_next_example_completed),
      workflow_executions(:irida_next_example_completed_2_files)
    ]

    visit workflow_executions_path

    selected_workflows.each do |workflow_execution|
      find("input[type='checkbox'][value='#{workflow_execution.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.delete_workflow_executions')

    within('dialog[open]') do
      click_button I18n.t('shared.workflow_executions.destroy_multiple_confirmation_dialog.submit_button')
    end

    assert_text I18n.t('concerns.workflow_execution_actions.destroy_multiple.success')
    selected_workflows.each { |workflow_execution| assert_no_text workflow_execution.id }
  end

  test 'bulk cancel submits selected workflows through the confirmation dialog' do
    selected_workflows = [
      workflow_executions(:irida_next_example_running),
      workflow_executions(:irida_next_example_new)
    ]

    visit workflow_executions_path

    selected_workflows.each do |workflow_execution|
      find("input[type='checkbox'][value='#{workflow_execution.id}']").click
    end

    click_button I18n.t('shared.workflow_executions.actions_dropdown.label')
    click_button I18n.t('shared.workflow_executions.actions_dropdown.cancel_workflow_executions')

    within('dialog[open]') do
      click_button I18n.t('shared.workflow_executions.cancel_multiple_confirmation_dialog.submit_button')
    end

    assert_text I18n.t('concerns.workflow_execution_actions.cancel_multiple.success')
  end

  private

  def select_state_advanced_search_field
    if has_selector?("input[role='combobox']", visible: :visible)
      find("input[role='combobox']", visible: :visible).send_keys(
        I18n.t('workflow_executions.table_component.state'),
        :enter
      )
    else
      find("select[name$='[field]']", visible: :visible).find("option[value='state']").select_option
    end
  end
end
