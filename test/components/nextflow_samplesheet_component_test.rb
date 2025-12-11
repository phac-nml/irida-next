# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  # samplesheet component testing now has to use the nextflow_component
  # (not nextflow_samplesheet_component) as the samplesheet now requires the nextflow_component to be rendered
  # for stimulus connection.

  setup do
    @user = users(:john_doe)
    login_as @user
  end

  test 'default' do
    visit('rails/view_components/nextflow_samplesheet_component/default')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 5
        assert_selector 'tr:first-child th:last-child', text: 'STRANDEDNESS (REQUIRED)'
      end

      assert_text I18n.t('components.nextflow_component.loading_complete')
    end
  end

  test 'with reference files' do
    visit('rails/view_components/nextflow_samplesheet_component/with_reference_files')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 4
        assert_selector 'tr:first-child th:last-child', text: 'REFERENCE_ASSEMBLY'
      end

      assert_text I18n.t('components.nextflow_component.loading_complete')
    end
  end

  test 'with metadata' do
    visit('rails/view_components/nextflow_samplesheet_component/with_metadata')
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

      assert_text I18n.t('components.nextflow_component.loading_complete')
    end
  end

  test 'with samplesheet overrides' do
    visit('rails/view_components/nextflow_samplesheet_component/with_samplesheet_overrides')
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

      assert_text I18n.t('components.nextflow_component.loading_complete')
    end
  end
end
