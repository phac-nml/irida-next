# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    workflow = Irida::Pipeline.new(
      {
        'name' => 'phac-nml/iridanextexample',
        'description' => 'This is a test workflow',
        'url' => 'https://nf-co.re/testpipeline'
      },
      { 'name' => '2.0.0' },
      Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
      Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json')
    )

    render_inline NextflowComponent.new(
      workflow:,
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      url: 'https://nf-co.re/testpipeline',
      namespace_id: 'SDSDDFDSFDS',
      fields: %w[metadata_1 metadata_2 metadata_3]
    )

    assert_selector 'form' do
      assert_selector 'h1', text: 'phac-nml/iridanextexample', count: 1
      assert_selector '.samplesheet-table .table-column:first-child .table-td', count: 3
      assert_no_selector 'input[type=text]'
    end
  end
end
