# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentSystemTest < ApplicationSystemTestCase
  # samplesheet component testing now has to use the nextflow_component
  # (not nextflow_samplesheet_component) as the samplesheet now requires the nextflow_component to be rendered
  # for stimulus connection.

  setup do
    @sample1 = samples(:sample43)
    @sample2 = samples(:sample44)
    @user = users(:john_doe)
    login_as @user
  end

  test 'native form submission validates every required parameter and restores file selector focus' do
    login_as users(:snvphyl_user)
    namespace = projects(:snvphyl_project).namespace
    visit "/rails/view_components/nextflow/base_component/required_parameters?namespace_id=#{namespace.id}"
    assert_selector '[data-controller-connected="true"]'
    form_selector = '[data-nextflow--v2--samplesheet-target="form"]'
    error_selector = '[data-nextflow--v2--samplesheet-target="formFieldError"]'
    # Observe whether validation allowed the native submit, without navigating away from the preview.
    page.execute_script <<~JS
      const form = document.querySelector('#{form_selector}');
      document.addEventListener('submit', (event) => {
        if (event.target !== form) return;
        form.dataset.validationPassed = String(!event.defaultPrevented);
        event.preventDefault();
      });
    JS

    find_button(I18n.t('workflow_executions.submissions.create.submit')).send_keys(:enter)
    assert_selector "#{form_selector}[data-validation-passed='false']"
    within(error_selector) do
      %w[Project Count Mode Reference].each { |label| assert_text label }
      assert_no_text 'Enabled'
      assert_no_text "Name can't be blank"
    end
    assert_equal 'workflow_execution_workflow_params_project_name',
                 page.evaluate_script('document.activeElement.id')
    assert_selector '#workflow_execution_workflow_params_project_name_error', text: "Project name can't be blank"
    assert_selector '#workflow_execution_workflow_params_reference_error', text: "Reference file can't be blank"
    page.current_window.resize_to(360, 900)
    page.execute_script("document.documentElement.classList.add('dark')")
    assert_component_accessible
    assert page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.workflow-parameter')).every((field) =>
        field.scrollWidth <= field.clientWidth
      )
    JS
    page.current_window.resize_to(1280, 1024)
    page.execute_script("document.documentElement.classList.remove('dark')")

    fill_in 'Project name', with: 'Test project'
    fill_in 'Count', with: '0'
    select 'fast', from: 'Mode'
    click_button I18n.t('workflow_executions.submissions.create.submit')
    assert_selector '#workflow_execution_workflow_params_reference_link[aria-invalid="true"]'
    assert_equal 'workflow_execution_workflow_params_reference_link',
                 page.evaluate_script('document.activeElement.id')

    # Keyboard activation opens the file selector; Turbo replaces the link and hidden input.
    find('#workflow_execution_workflow_params_reference_link').send_keys(:enter)
    within('#file_selector_dialog') do
      choose "attachment_id_#{attachments(:snvphyl_project_attachment_ref).id}"
      click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
    end
    assert_selector '#workflow_execution_workflow_params_reference[data-required="true"]', visible: :all
    click_button I18n.t('workflow_executions.submissions.create.submit')
    assert_selector "#{form_selector}[data-validation-passed='true']"
    assert_no_selector error_selector
  end

  test 'default' do
    visit('/rails/view_components/nextflow/samplesheet_component/default')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 5
        assert_selector 'tr:first-child th:last-child', text: 'STRANDEDNESS (REQUIRED)'
      end
    end
  end

  test 'with reference files' do
    visit('/rails/view_components/nextflow/samplesheet_component/with_reference_files')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 4
        assert_selector 'tr:first-child th:last-child', text: 'REFERENCE_ASSEMBLY'
      end
    end
  end

  test 'with metadata' do
    visit('/rails/view_components/nextflow/samplesheet_component/with_metadata')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 1)
      within('table') do
        assert_selector 'thead th', count: 4
        within('tr:first-child th:nth-child(2)') do
          assert_selector 'select', text: 'pfge_pattern (default)'
        end
        within('tr:first-child th:nth-child(3)') do
          assert_selector 'select', text: 'country (default)'
        end
        within('tr:first-child th:last-child') do
          assert_selector 'select', text: 'insdc_accession (default)'
        end
      end
    end
  end

  test 'with samplesheet overrides' do
    visit('/rails/view_components/nextflow/samplesheet_component/with_samplesheet_overrides')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 20
        within('tr:first-child th:nth-child(5)') do
          assert_selector 'select', text: 'new_isolates_date (default)'
        end
        within('tr:first-child th:nth-child(6)') do
          assert_selector 'select', text: 'predicted_primary_identification_name (default)'
        end
        within('tr:first-child th:nth-child(7)') do
          assert_selector 'select', text: 'metadata_3 (default)'
        end
      end
    end
  end
end
