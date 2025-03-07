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

    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 5
      table.assert_selector '.table-column:last-of-type .table-header', text: 'STRANDEDNESS (REQUIRED)'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: @sample1.puid
      table.assert_selector '.table-column:nth-of-type(2) .table-td:first-of-type', text: @sample1.name
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type select option', count: 4
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type select option:nth-of-type(2)',
                            text: 'forward'
    end
  end

  test 'with reference files' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_reference_files?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 4
      table.assert_selector '.table-column:last-of-type .table-header', text: 'REFERENCE_ASSEMBLY'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: @sample1.puid
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type a',
                            text: I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file')
    end
  end

  test 'with metadata' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_metadata?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength
    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 4
      table.assert_selector '.table-column:nth-of-type(2) .table-header select', count: 1
      table.assert_selector '.table-column:nth-of-type(2) .table-header select', text: 'pfge_pattern (default)'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: @sample1.puid
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type', text: 'ERR86724108'
      table.assert_selector '.table-column:first-of-type .table-td:nth-child(2)', text: @sample2.puid
      table.assert_selector '.table-column:last-of-type .table-td:last-of-type', text: 'ERR31551163'
    end
  end

  test 'with metadata and values' do
    visit("/rails/view_components/nextflow_samplesheet_component/with_metadata_and_values?sample_ids[]=#{@sample1.id}&sample_ids[]=#{@sample2.id}") # rubocop:disable Layout/LineLength
    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 12
      table.assert_selector '.table-column:last-of-type .table-header select', count: 1
      table.assert_selector '.table-column:last-of-type .table-header select', text: ''
      # table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: @sample1.puid
      # table.assert_selector '.table-column:last-of-type .table-td:first-of-type', text: 'ERR86724108'
      table.assert_selector '.table-column:first-of-type .table-td:nth-child(2)', text: @sample2.puid
      # table.assert_selector '.table-column:last-of-type .table-td:last-of-type', text: 'ERR31551163'
    end

    assert_selector 'input[id="workflow_execution_workflow_params_metadata_8_header"][value="metadata_8"]'

    # find('select[data-action="change->nextflow--samplesheet#pageSelected"]').find('option[value="4"]').select_option
    # assert_selector
    # find('#field-metadata_8').click
    # find('option[value="country"]')[7].click
    find('#field-metadata_8').find('option[value="country"]').select_option
    # assert_selector '.samplesheet-table' do |table|
    #   table.assert_selector '.table-header', count: 12
    #   table.assert_selector '.table-column:last-of-type .table-header select', count: 1
    #   table.assert_selector '.table-column:last-of-type .table-header select', text: 'Country'
    #   # table.assert_selector '.table-column:first-of-type .table-td', count: 2
    #   table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: @sample1.puid
    #   # table.assert_selector '.table-column:last-of-type .table-td:first-of-type', text: 'ERR86724108'
    #   table.assert_selector '.table-column:first-of-type .table-td:nth-child(2)', text: @sample2.puid
    #   # table.assert_selector '.table-column:last-of-type .table-td:last-of-type', text: 'ERR31551163'
    # end
    # assert_no_selector 'input[id="workflow_execution_workflow_params_metadata_8_header"][value="metadata_8"]'
    assert_selector 'input[id="workflow_execution_workflow_params_metadata_8_header"][value="country"]'
  end
end
