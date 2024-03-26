# frozen_string_literal: true

require 'view_component_test_case'

class NextflowSamplesheetComponentTest < ViewComponentTestCase
  test 'default' do
    render_inline Nextflow::SamplesheetComponent.new(
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/samplesheet_schema.json'))
    )

    assert_selector 'table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last', text: 'strandedness'
      assert_selector 'tbody tr', count: 3
      assert_selector 'tbody tr:first td:first', text: samples(:sample1).puid
      assert_selector 'tbody tr:first td:nth-child(3) select', count: 1
      assert_selector 'tbody tr:first td:nth-child(4) select', count: 1
      assert_selector 'tbody tr:first td:nth-child(5) select', count: 1
    end
  end

  test 'with reference files' do
    render_inline Nextflow::SamplesheetComponent.new(
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/samplesheet_schema_snvphyl.json'))
    )

    assert_selector 'table' do
      assert_selector 'thead th', count: 4
      assert_selector 'thead th:last', text: 'reference_assembly'
      assert_selector 'tbody tr', count: 3
      assert_selector 'tbody tr:first td:first', text: samples(:sample1).puid
      assert_selector 'tbody tr:first td:nth-child(3) select', count: 1
      assert_selector 'tbody tr:first td:nth-child(4) select', count: 1
      assert_selector 'tbody tr:first td:nth-child(5) select', count: 1
      assert_selector 'tbody tr:first td:last select option', count: 2
    end
  end
end
