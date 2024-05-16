# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
    @pipeline_schema_file_dir = 'tmp/storage/pipelines'

    Irida::Pipelines.pipeline_config_dir = 'test/config/pipelines_with_overrides'
    Irida::Pipelines.pipeline_schema_file_dir = @pipeline_schema_file_dir

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body: '', headers: { etag: '[W/"f1Fg"]' })
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'pipelines with overrides' do
    workflow1 = Irida::Pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.2')
    assert_equal 'DEFAULT PROJECT NAME',
                 workflow1.workflow_params[:input_output_options][:properties][:project_name][:default]

    workflow2 = Irida::Pipelines.find_pipeline_by('phac-nml/iridanextexample', '1.0.1')
    assert_equal 'UNIQUE PROJECT NAME',
                 workflow2.workflow_params[:input_output_options][:properties][:project_name][:default]
  end
end
