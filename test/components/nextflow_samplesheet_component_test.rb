# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ApplicationSystemTestCase
  test 'default' do
    visit('/rails/view_components/nextflow_samplesheet_component/default')

    assert_selector '.sample-sheet table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last-of-type', text: 'STRANDEDNESS'
      assert_selector 'tbody tr', count: 2
      assert_selector 'tbody tr:first-of-type td:first-of-type', text: Sample.first.puid
      assert_selector 'tbody tr:first-of-type td > select', count: 3
      assert_selector 'tbody tr:first-of-type td:last-of-type > select'
      assert_selector 'tbody tr:first-of-type td:last-of-type > select option', count: 3
      assert_selector 'tbody tr:first-of-type td:last-of-type > select option:first-of-type', text: 'forward'
    end
  end

  test 'with reference files' do
    render_inline Nextflow::SamplesheetComponent.new(
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/samplesheet_schema_snvphyl.json')),
      fields: %w[metadata_1 metadata_2 metadata_3],
      namespace_id: 'KDSLFJSDLKFJLKDSJF'
    )

    assert_selector '.sample-sheet table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last', text: 'reference_assembly'
      assert_selector 'tbody tr', count: 3
      assert_selector 'tbody tr:first td:first', text: samples(:sample1).puid
      assert_selector 'tbody tr:first td > select', count: 3
    end
  end

  test 'with metadata' do
    render_inline Nextflow::SamplesheetComponent.new(
      samples: [samples(:sample43), samples(:sample44)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/samplesheet_schema_meta.json')),
      fields: %w[insdc_accession],
      namespace_id: 'KDSLFJSDLKFJLKDSJF'
    )

    assert_selector '.sample-sheet table' do |table|
      table.assert_selector 'thead th', count: 3
      table.assert_selector 'thead th:last select', count: 1
      table.assert_selector 'thead th:last select', text: 'insdc_accession'
      table.assert_selector 'tbody tr', count: 2
      table.assert_selector 'tbody tr:first td:first', text: samples(:sample43).puid
      table.assert_selector 'tbody tr:first', text: 'ERR86724108'
      table.assert_selector 'tbody tr:last td:first', text: samples(:sample44).puid
      table.assert_selector 'tbody tr:last', text: 'ERR31551163'

      assert_selector 'thead th:last' do |_td|
        click_on 'insdc_accession'
        assert_selector 'option', count: 2
      end
    end
  end
end
