# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    workflow = Struct.new(:name, :id, :description, :version, :metadata)
    metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }

    render_inline NextflowComponent.new(
      workflow: workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0', metadata),
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/nextflow_schema.json')),
      url: 'https://nf-co.re/testpipeline'
    )

    assert_selector 'form' do
      assert_selector 'h1', text: 'nf-core/iridanext pipeline parameters', count: 1
      assert_selector 'tbody tr', count: 3
      assert_selector 'input[type=text]', count: 1
    end
  end
end
