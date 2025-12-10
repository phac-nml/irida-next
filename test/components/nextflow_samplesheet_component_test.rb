# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetComponentTest < ViewComponentTestCase
  # samplesheet component testing now has to use the nextflow_component
  # (not nextflow_samplesheet_component) as the samplesheet now requires the nextflow_component to be rendered
  # for stimulus connection.
  test 'default' do
    visit('/rails/view_components/nextflow_samplesheet_component/default')

    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 5
      table.assert_selector 'thead tr:first-of-type th:last-of-type', text: 'STRANDEDNESS (REQUIRED)'
    end
  end

  test 'with reference files' do
    visit('/rails/view_components/nextflow_samplesheet_component/with_reference_files')

    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 4
      table.assert_selector 'thead tr:first-of-type th:last-of-type', text: 'REFERENCE_ASSEMBLY'
    end
  end

  test 'with metadata' do
    visit('/rails/view_components/nextflow_samplesheet_component/with_metadata')
    assert_selector 'table' do |table|
      table.assert_selector 'thead th', count: 4
      table.assert_selector 'thead tr:first-of-type th:nth-of-type(2) select', count: 1
      table.assert_selector 'thead tr:first-of-type th:nth-of-type(2) select', text: 'pfge_pattern (default)'
    end
  end

  test 'with samplesheet overrides' do
    entry = {
      url: 'https://github.com/phac-nml/fastmatchirida',
      name: 'PNC Fast Match',
      description: 'IRIDA Next PNC Fast Match Pipeline',
      samplesheet_schema_overrides: {
        items: {
          properties: {
            metadata_1: { # rubocop:disable Naming/VariableNumber
              'x-irida-next-selected': 'new_isolates_date'
            },
            metadata_2: { # rubocop:disable Naming/VariableNumber
              'x-irida-next-selected': 'predicted_primary_identification_name'
            }
          },
          required: %w[
            sample
            mlst_alleles
          ]
        }
      },
      versions: [
        {
          name: '0.4.1',
          automatable: true
        }
      ]
    }.with_indifferent_access

    workflow = Irida::Pipeline.new('PNC Fast Match', entry, { name: '0.4.1' },
                                   Rails.root.join(
                                     'test/fixtures/files/nextflow/nextflow_schema_fastmatch.json'
                                   ),
                                   Rails.root.join(
                                     'test/fixtures/files/nextflow/samplesheet_schema_fastmatch.json'
                                   ))

    render_inline NextflowComponent.new(
      workflow:,
      sample_count: 2,
      url: 'a_url',
      namespace_id: projects(:project1).namespace,
      fields: %w[age gender collection_date]
    )

    within('div[data-controller-connected="true"]') do
      assert_selector 'table' do |table|
        table.assert_selector 'thead th', count: 20
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(5) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(5) select', text: 'new_isolates_date (default)'
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(6) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(6) select',
                              text: 'predicted_primary_identification_name (default)'
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(7) select', count: 1
        table.assert_selector 'thead tr:first-of-type th:nth-of-type(7) select',
                              text: 'metadata_3 (default)'
      end

      assert_field 'The header name of metadata column 1.', with: 'new_isolates_date'
      assert_field 'The header name of metadata column 2.', with: 'predicted_primary_identification_name'

      assert_field 'The header name of metadata column 3.', with: 'metadata_3'

      select('age', from: 'field-metadata_3')
      assert_field 'The header name of metadata column 3.', with: 'age'
    end
  end
end
