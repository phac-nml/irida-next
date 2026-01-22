# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  # samplesheet component testing now has to use the nextflow_component
  # (not nextflow_samplesheet_component) as the samplesheet now requires the nextflow_component to be rendered
  # for stimulus connection.

  setup do
    @sample1 = samples(:sample43)
    @sample2 = samples(:sample44)
    @user = users(:john_doe)
    login_as @user
  end

  test 'default with feature flag' do
    Flipper.enable(:prerendered_samplesheet)
    visit('rails/view_components/prerendered_nextflow_samplesheet_component/default')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 5
        assert_selector 'tr:first-child th:last-child', text: 'STRANDEDNESS (REQUIRED)'
      end
    end
  end

  test 'default without feature flag' do
    visit("/rails/view_components/nextflow_samplesheet_component/default?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 5
      table.assert_selector 'thead tr:first-of-type th:last-of-type', text: 'STRANDEDNESS (REQUIRED)'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first-of-type th:first-of-type', text: @sample1.puid
      table.assert_selector 'tbody tr:first-of-type td:first-of-type', text: @sample1.name
      table.assert_selector 'tbody tr:first-of-type td:last-of-type select option', count: 4
      table.assert_selector 'tbody tr:first-of-type td:last-of-type select option:nth-of-type(2)',
                            text: 'forward'
    end
  end

  test 'with reference files with feature flag' do
    Flipper.enable(:prerendered_samplesheet)
    visit('rails/view_components/prerendered_nextflow_samplesheet_component/with_reference_files')
    within('div[id="nextflow-container"][data-controller-connected="true"]') do
      assert_text I18n.t('components.nextflow_component.loading_samplesheet', count: 2)
      within('table') do
        assert_selector 'thead th', count: 4
        assert_selector 'tr:first-child th:last-child', text: 'REFERENCE_ASSEMBLY'
      end
    end
  end

  test 'with reference files without feature flag' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_reference_files?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 4
      table.assert_selector 'thead tr:first-of-type th:last-of-type', text: 'REFERENCE_ASSEMBLY'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first-of-type th:first-of-type', text: @sample1.puid
      table.assert_selector 'tbody tr:first-of-type td:last-of-type a',
                            text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
    end
  end

  test 'with metadata with feature flag' do
    Flipper.enable(:prerendered_samplesheet)
    visit('rails/view_components/prerendered_nextflow_samplesheet_component/with_metadata')
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

  test 'with metadata without feature flag' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_metadata?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength
    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 4
      table.assert_selector 'thead tr:first-of-type th:nth-of-type(2) select', count: 1
      table.assert_selector 'thead tr:first-of-type th:nth-of-type(2) select', text: 'pfge_pattern (default)'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first-of-type th:first-of-type', text: @sample1.puid
      table.assert_selector 'tbody tr:first-of-type td:last-of-type', text: 'ERR86724108'
      table.assert_selector 'tbody tr:last-of-type th:first-of-type', text: @sample2.puid
      table.assert_selector 'tbody tr:last-of-type td:last-of-type', text: 'ERR31551163'
    end
  end

  test 'with samplesheet overrides with feature flag' do
    Flipper.enable(:prerendered_samplesheet)
    visit('rails/view_components/prerendered_nextflow_samplesheet_component/with_samplesheet_overrides')
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

  test 'with samplesheet overrides without feature flag' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_samplesheet_overrides?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength

    within('div[data-controller-connected="true"]') do
      assert_selector 'table' do |table|
        table.assert_selector 'thead th', count: 20
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(5) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(5) select', text: 'new_isolates_date (default)'
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(6) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(6) select',
                              text: 'predicted_primary_identification_name (default)'
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(7) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(7) select',
                              text: 'metadata_3 (default)'
        table.assert_selector 'tbody tr', count: 2
        table.assert_selector 'tbody tr:first-of-type th:first-of-type', text: @sample1.puid
        table.assert_selector 'tbody tr:first-of-type td:nth-of-type(1)', text: @sample1.name
        table.assert_selector 'tbody tr:last-of-type th:first-of-type', text: @sample2.puid
        table.assert_selector 'tbody tr:last-of-type td:nth-of-type(1)', text: @sample2.name
        assert_field 'The header name of metadata column 1.', with: 'new_isolates_date'
        assert_field 'The header name of metadata column 2.', with: 'predicted_primary_identification_name'

        assert_field 'The header name of metadata column 3.', with: 'metadata_3'

        select('age', from: 'field-metadata_3')
        assert_field 'The header name of metadata column 3.', with: 'age'
      end
    end
  end
end
