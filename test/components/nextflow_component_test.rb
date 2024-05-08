# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    workflow = Irida::Pipeline.new(
      {
        'name' => 'phac-nml/iridanextexample',
        'description' => 'This is a test workflow',
        'url' => 'https://nf-co.re/testpipeline',
        'versions' => [
          {
            name: '1.0.2'
          }
        ]
      },
      '1.0.2',
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
      assert_selector 'input[type=text][name="workflow_execution[name]"]'
    end
  end

  test 'default with overrides' do
    workflow = Irida::Pipeline.new(
      {
        'name' => 'phac-nml/iridanextexample',
        'description' => 'This is a test workflow',
        'url' => 'https://nf-co.re/testpipeline',
        'versions' => [
          {
            name: '1.0.2',
            parameter_overrides: {
              definitions: {
                input_output_options: {
                  properties: {
                    project_name: {
                      type: 'string',
                      default: 'Shit my dad did',
                      pattern: '^\\S+$',
                      description: 'The name of the project.',
                      fa_icon: 'fas fa-tag'
                    }
                  }
                }
              }
            }
          }
        ]
      },
      '1.0.2',
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
      assert_selector 'input[type=text][name="workflow_execution[name]"]'
      assert_selector 'label', text: 'The custom of the project.'
    end
  end
end
