# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    workflow = Struct.new(:name, :id, :description, :version, :metadata, :type, :type_version, :engine,
                          :engine_version, :url, :execute_loc)
    metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }

    render_inline NextflowComponent.new(
      workflow: workflow.new('phac-nml/iridanextexample', 1, 'IRIDA Next Example Pipeline', '1.0.1', metadata,
                             'DSL2', '22.10.7', 'nextflow', '',
                             'https://github.com/phac-nml/iridanextexample', 'azure'),
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/nextflow_schema.json')),
      url: 'https://nf-co.re/testpipeline'
    )

    assert_selector 'form' do
      assert_selector 'h1', text: 'phac-nml/iridanextexample pipeline parameters', count: 1
      assert_selector 'tbody tr', count: 3
      assert_no_selector 'input[type=text]'
    end
  end
end
