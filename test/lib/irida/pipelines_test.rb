# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    # Read in schema file to json
    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json')

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"f1Fg"]' })

    @pipelines = Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines/pipelines.json',
                                      pipeline_schema_file_dir: @pipeline_schema_file_dir)
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'registers pipelines' do
    assert_not @pipelines.pipelines.empty?

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.2')
    assert_not_nil workflow

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.1')
    assert_not_nil workflow

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.0')
    assert_not_nil workflow
  end

  test 'automatable pipelines' do
    assert_not @pipelines.pipelines('automatable').empty?

    assert @pipelines.pipelines('automatable')['phac-nml/iridanextexample_1.0.2']
    assert_not @pipelines.pipelines('automatable')['phac-nml/iridanextexample_1.0.1']
    assert_not @pipelines.pipelines('automatable')['phac-nml/iridanextexample_1.0.0']
  end

  test 'executable pipelines' do
    assert_not @pipelines.pipelines('executable').empty?

    assert @pipelines.pipelines('executable')['phac-nml/iridanextexample_1.0.2']
    assert @pipelines.pipelines('executable')['phac-nml/iridanextexample_1.0.1']
    assert_not @pipelines.pipelines('executable')['phac-nml/iridanextexample_1.0.0']
  end

  test 'fail on trying to get new etag for cached pipeline' do
    # The regular pipelines have already been loaded once and files written to the pipeline schema file dir.
    # This simulates a restart where the init checks to fetch a fresh etag to compare versions, but fails
    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 404)
    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 404)

    pipeline_refresh = Irida::Pipelines.new(
      pipeline_config_file: 'test/config/pipelines_fail_to_get_etag_for_cached_pipeline/pipelines.json',
      pipeline_schema_file_dir: @pipeline_schema_file_dir
    )

    pl = pipeline_refresh.pipelines['phac-nml/iridanextexample_1.0.2']
    assert_not_nil pl
    assert_not pl.executable
  end

  test 'fail on github not accessible' do
    # if github is inaccessible we want to hard crash with a custom exception
    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 503)
    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 503)

    error = assert_raises(Irida::Pipelines::PipelinesInvalidUrlException) do
      Irida::Pipelines.new(
        pipeline_config_file: 'test/config/pipelines_fail_to_get_etag_for_cached_pipeline/pipelines.json',
        pipeline_schema_file_dir: @pipeline_schema_file_dir
      )
    end

    assert_equal '503', error.code
  end
end
