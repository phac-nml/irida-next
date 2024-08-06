# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  test 'default' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 5
      table.assert_selector '.table-column:last-of-type .table-header', text: 'STRANDEDNESS (REQUIRED)'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: sample1.puid
      table.assert_selector '.table-column:nth-of-type(2) .table-td:first-of-type', text: sample1.name
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type select option', count: 4
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type select option:nth-of-type(2)',
                            text: 'forward'
    end
  end

  test 'with reference files' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?schema_file=samplesheet_schema_snvphyl.json&sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 4
      table.assert_selector '.table-column:last-of-type .table-header', text: 'REFERENCE_ASSEMBLY'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: sample1.puid
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type select option', count: 1
    end
  end

  test 'with metadata' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?schema_file=samplesheet_schema_meta.json&sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.samplesheet-table' do |table|
      table.assert_selector '.table-header', count: 3
      table.assert_selector '.table-column:last-of-type .table-header select', count: 1
      table.assert_selector '.table-column:last-of-type .table-header select', text: 'insdc_accession'
      table.assert_selector '.table-column:first-of-type .table-td', count: 2
      table.assert_selector '.table-column:first-of-type .table-td:first-of-type', text: sample1.puid
      table.assert_selector '.table-column:last-of-type .table-td:first-of-type', text: 'ERR86724108'
      table.assert_selector '.table-column:first-of-type .table-td:nth-child(2)', text: sample2.puid
      table.assert_selector '.table-column:last-of-type .table-td:last-of-type', text: 'ERR31551163'
    end
  end
end
