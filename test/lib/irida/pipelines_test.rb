# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = 'tmp/storage/pipelines'

    Irida::Pipelines.pipeline_config_dir = 'test/config/pipelines'
    Irida::Pipelines.pipeline_schema_file_dir = @pipeline_schema_file_dir

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag:  '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag:  '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag:  '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag:  '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag:  '[W/"f1Fg"]' })
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'registers pipelines' do
    Irida::Pipelines.register_pipelines

    assert_not Irida::Pipelines.available_pipelines.empty?

    workflow = Irida::Pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.2')
    assert_not_nil workflow

    workflow = Irida::Pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.1')
    assert_not_nil workflow

    workflow = Irida::Pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.0')
    assert_not_nil workflow
  end

  test 'automatable pipelines' do
    Irida::Pipelines.register_pipelines

    assert_not Irida::Pipelines.automatable_pipelines.empty?

    assert Irida::Pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.2']
    assert_not Irida::Pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.1']
    assert_not Irida::Pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.0']
  end

  test 'pipelines with overrides' do
    @pipeline_schema_file_dir = 'tmp/storage/pipelines'

    Irida::Pipelines.pipeline_config_dir = 'test/config/pipelines_with_overrides'
    Irida::Pipelines.pipeline_schema_file_dir = @pipeline_schema_file_dir
    workflow = Irida::Pipelines.find_pipeline_by('phac-nml/mikrokondo', '0.1.2')

    assert workflow.workflow_params[:databases_and_pre_computed_files][:properties][:kraken2_db].key?(:enum)

    kraken2_db_enum = workflow.workflow_params[:databases_and_pre_computed_files][:properties][:kraken2_db][:enum]
    assert_equal 2, kraken2_db_enum.length
    assert_equal 'DBNAME', kraken2_db_enum[0][0]
    assert_equal 'PATH_TO_DB', kraken2_db_enum[0][1]
    assert_equal 'ANOTHER_DB', kraken2_db_enum[1][0]
    assert_equal 'ANOTHER_PATH', kraken2_db_enum[1][1]
  end
end
