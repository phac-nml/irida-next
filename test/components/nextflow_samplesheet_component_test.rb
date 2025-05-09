# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  # samplesheet component testing now has to use the nextflow_component
  # (not nextflow_samplesheet_component) as the samplesheet now requires the nextflow_component to be rendered
  # for stimulus connection.
  setup do
    @sample1 = samples(:sample43)
    @sample2 = samples(:sample44)
  end
  test 'default' do
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

  test 'with reference files' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_reference_files?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 4
      table.assert_selector 'thead tr:first-of-type th:last-of-type', text: 'REFERENCE_ASSEMBLY'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first-of-type th:first-of-type', text: @sample1.puid
      table.assert_selector 'tbody tr:first-of-type td:last-of-type a',
                            text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
    end
  end

  test 'with metadata' do
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
end
