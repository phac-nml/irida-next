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

  test 'files tab page-size selector reloads tab content through browser interaction' do
    workflow_execution = workflow_executions(:irida_next_example_completed_with_output)

    visit workflow_execution_path(workflow_execution)

    within 'main' do
      click_on I18n.t('workflow_executions.show.tabs.files')
    end

    assert_selector '#files-panel-content tbody tr', count: 2

    select '10', from: 'pagy-limit-select'

    assert_selector '#files-panel-content a[href*="limit=10"][href*="tab=files"]'
    assert_selector '#files-panel-content tbody tr', count: 2
    assert_selector '#files-panel-content #pagy-limit-select option[value="10"]:checked'
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

  test 'delete action opens turbo confirmation dialog and completes through browser interaction' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    visit workflow_executions_path

    within("tr[id='#{dom_id(workflow_execution)}']") do
      click_button I18n.t('common.actions.delete')
    end

    assert_text I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.title')
    click_button I18n.t(:'shared.workflow_executions.destroy_confirmation_dialog.submit_button')

    assert_text I18n.t(:'concerns.workflow_execution_actions.destroy.success',
                       workflow_name: workflow_execution.workflow.name)
    assert_no_text workflow_execution.id
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

  test 'edit action opens turbo dialog and updates workflow summary through browser interaction' do
    workflow_execution = workflow_executions(:irida_next_example_new)
    new_name = 'New Name'
    name_label = I18n.t('common.labels.name')
    run_from_label =
      I18n.t(:"workflow_executions.summary.run_from_namespace.#{workflow_execution.namespace.type.downcase}")
    shared_with_label =
      I18n.t(:"workflow_executions.summary.shared_with_namespace.#{workflow_execution.namespace.type.downcase}")

    visit workflow_execution_path(workflow_execution)

    assert_selector 'h1', text: workflow_execution.name
    assert_selector 'dt', exact_text: name_label
    assert_selector 'dt', text: run_from_label
    assert_no_selector 'dt', text: shared_with_label

    click_button I18n.t('common.actions.edit')

    within('dialog') do
      assert_selector 'h1', text: I18n.t('workflow_executions.edit_dialog.title')
      assert_selector 'p',
                      text: I18n.t('workflow_executions.edit_dialog.description',
                                   workflow_execution_id: workflow_execution.id)
      assert_selector 'label', text: name_label

      fill_in placeholder: I18n.t('workflow_executions.edit_dialog.name_placeholder'),
              with: new_name
      check I18n.t(
        :"workflow_executions.edit_dialog.shared_with_namespace.#{workflow_execution.namespace.type.downcase}"
      )

      click_button I18n.t(:'workflow_executions.edit_dialog.submit_button')
    end

    assert_selector 'h1', text: new_name
    assert_selector 'dt', exact_text: name_label
    assert_selector 'dd', text: new_name
    assert_no_selector 'dt', text: run_from_label
    assert_selector 'dt', text: shared_with_label
    assert_selector 'dd', text: workflow_execution.namespace.name
    assert_selector 'dd', text: workflow_execution.namespace.puid
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
