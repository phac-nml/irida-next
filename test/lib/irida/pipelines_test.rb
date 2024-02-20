# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: ['a1Ab'] })

    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: ['b1Bc'] })

    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: ['c1Cd'] })

    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: ['d1De'] })

    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: ['e1Ef'] })

    stub_request(:any, 'https://raw.githubusercontent.com//phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: ['f1Fg'] })

    @old_pipeline_config_dir = 'config/pipelines/'
    @old_pipeline_schema_file_dir = 'private/pipelines'

    Irida::Pipelines.PIPELINE_CONFIG_DIR = 'test/config/pipelines/'
    Irida::Pipelines.PIPELINE_SCHEMA_FILE_DIR = '/pipelines'
  end

  teardown do
    Irida::Pipelines.PIPELINE_CONFIG_DIR = @old_pipeline_config_dir
    Irida::Pipelines.PIPELINE_SCHEMA_FILE_DIR = @old_pipeline_schema_file_dir
  end

  test 'registers pipelines' do
    Irida::Pipelines.register_pipelines

    assert_not Irida::Pipelines.available_pipelines.empty?
  end
end
