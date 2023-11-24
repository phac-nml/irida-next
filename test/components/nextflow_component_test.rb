# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    render_inline NextflowComponent.new(
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      schema: JSON.parse(File.read('test/fixtures/files/nextflow/nextflow_schema.json')),
      url: 'https://nf-co.re/testpipeline'
    )

    assert_selector 'form' do
      assert_selector 'h1', text: 'nf-core/testpipeline pipeline parameters', count: 1
      assert_selector 'input[type=file]', count: 2
      assert_selector 'input[type=text]', count: 5
    end
  end
end
