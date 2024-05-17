# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = 'tmp/storage/pipelines'

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

    @pipelines = Irida::Pipelines.new(pipeline_config_dir: 'test/config/pipelines', pipeline_schema_file_dir: @pipeline_schema_file_dir)
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'registers pipelines' do
    assert_not @pipelines.available_pipelines.empty?

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.2')
    assert_not_nil workflow

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.1')
    assert_not_nil workflow

    workflow = @pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.0')
    assert_not_nil workflow
  end

  test 'automatable pipelines' do
    assert_not @pipelines.automatable_pipelines.empty?

    assert @pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.2']
    assert_not @pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.1']
    assert_not @pipelines.automatable_pipelines['phac-nml/iridanextexample_1.0.0']
  end
end
