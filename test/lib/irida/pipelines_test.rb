# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

module Irida
  module Pipelines
    module_function

    def pipeline_config_dir=(new_value)
      @pipeline_config_dir = new_value
    end

    def pipeline_schema_file_dir=(new_value)
      @pipeline_schema_file_dir = new_value
    end
  end
end

class PipelinesTest < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = 'tmp/storage/pipelines'

    # Read in schema file to json
    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json')

    Irida::Pipelines.pipeline_config_dir = 'test/config/pipelines'
    Irida::Pipelines.pipeline_schema_file_dir = @pipeline_schema_file_dir

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
end
