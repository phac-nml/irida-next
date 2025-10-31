# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesOverrides < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    # Read in schema file to json
    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json')
    nextflow_fastmatch_body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema_fastmatch.json')
    nextflow_samplesheet_fastmatch_body = Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_fastmatch.json')

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.1/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.1/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.0/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/2.0.0/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"f1Fg"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/fastmatchirida/0.4.1/nextflow_schema.json')
      .to_return(status: 200, body: nextflow_fastmatch_body, headers: { etag: '[W/"g1gh"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/fastmatchirida/0.4.1/assets/schema_input.json')
      .to_return(status: 200, body: nextflow_samplesheet_fastmatch_body, headers: { etag: '[W/"h1hi"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/fastmatchirida/0.4.0/nextflow_schema.json')
      .to_return(status: 200, body: nextflow_fastmatch_body, headers: { etag: '[W/"i1ij"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/fastmatchirida/0.4.0/assets/schema_input.json')
      .to_return(status: 200, body: nextflow_samplesheet_fastmatch_body, headers: { etag: '[W/"j1kl"]' })
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'pipelines with overrides' do
    pipelines = Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_overrides/pipelines.json',
                                     pipeline_schema_file_dir: @pipeline_schema_file_dir)

    workflow1 = pipelines.find_pipeline_by('phac-nml/iridanextexample', '2.0.2')
    assert_equal 'DEFAULT PROJECT NAME',
                 workflow1.workflow_params[:input_output_options][:properties][:project_name][:default]

    workflow2 = pipelines.find_pipeline_by('phac-nml/iridanextexample', '2.0.1')
    assert_equal 'UNIQUE PROJECT NAME',
                 workflow2.workflow_params[:input_output_options][:properties][:project_name][:default]
  end

  test 'pipelines with samplesheet overrides at entry level' do
    pipelines = Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_overrides/pipelines.json',
                                     pipeline_schema_file_dir: @pipeline_schema_file_dir)

    workflow1 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.1')


    assert_equal 'new_isolates_date',
                 workflow1.samplesheet_schema[:items][:properties][:metadata_1][:"x-irida-next-selected"]

    assert_equal 'prediceted_primary_identification_name',
                 workflow1.samplesheet_schema[:items][:properties][:metadata_2][:"x-irida-next-selected"]

    assert_nil workflow1.samplesheet_schema[:items][:properties][:metadata_3][:"x-irida-next-selected"]

    assert_nil workflow1.samplesheet_schema[:items][:properties][:metadata_15][:"x-irida-next-selected"]
  end

  test 'pipelines with samplesheet overrides at version level' do
    pipelines = Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_overrides/pipelines.json',
                                     pipeline_schema_file_dir: @pipeline_schema_file_dir)


    workflow1 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.1')

    puts workflow1.workflow_params

    # assert_equal 'new_isolates_date',
    #              workflow1.samplesheet_schema[:items][:properties][:metadata_1][:"x-irida-next-selected"]

    # assert_equal 'prediceted_primary_identification_name',
    #              workflow1.samplesheet_schema[:items][:properties][:metadata_2][:"x-irida-next-selected"]

    # assert_nil workflow1.samplesheet_schema[:items][:properties][:metadata_3][:"x-irida-next-selected"]

    # assert_equal 'calc_earliest_date',
    #           workflow1.samplesheet_schema[:items][:properties][:metadata_15][:"x-irida-next-selected"]

    # workflow2 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.1')

    # assert_nil workflow2.samplesheet_schema[:items][:properties][:metadata_15][:"x-irida-next-selected"]

  end
end
