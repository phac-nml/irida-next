# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  test 'default' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.sample-sheet table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last-of-type', text: 'STRANDEDNESS'
      assert_selector 'tbody tr', count: 2
      assert_selector 'tbody tr:first-of-type td:first-of-type', text: sample1.puid
      assert_selector 'tbody tr:first-of-type td > select', count: 3
      assert_selector 'tbody tr:first-of-type td:last-of-type > select'
      assert_selector 'tbody tr:first-of-type td:last-of-type > select option', count: 3
      assert_selector 'tbody tr:first-of-type td:last-of-type > select option:first-of-type', text: 'forward'
    end
  end

  test 'with reference files' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?schema_file=samplesheet_schema_snvphyl.json&sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.sample-sheet table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last-of-type', text: 'REFERENCE_ASSEMBLY'
      assert_selector 'tbody tr', count: 2
      assert_selector 'tbody tr:first-of-type td:first-of-type', text: sample1.puid
      assert_selector 'tbody tr:first-of-type td > select', count: 3
      assert_selector 'tbody tr:first-of-type td:last-of-type > select option', count: 1
    end
  end

  test 'with metadata' do
    sample1 = samples(:sample43)
    sample2 = samples(:sample44)
    visit("/rails/view_components/nextflow_samplesheet_component/default?schema_file=samplesheet_schema_meta.json&sample_ids[]=#{sample1.id}&sample_ids[]=#{sample2.id}") # rubocop:disable Layout/LineLength

    assert_selector '.sample-sheet table' do |table|
      table.assert_selector 'thead th', count: 3
      table.assert_selector 'thead th:last-of-type select', count: 1
      table.assert_selector 'thead th:last-of-type select', text: 'insdc_accession'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first-of-type td:first-of-type', text: sample1.puid
      table.assert_selector 'tbody tr:first-of-type', text: 'ERR86724108'
      table.assert_selector 'tbody tr:last-of-type td:first-of-type', text: sample2.puid
      table.assert_selector 'tbody tr:last-of-type', text: 'ERR31551163'
    end
  end
end
