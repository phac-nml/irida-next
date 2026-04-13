# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesSchemaTest < ActiveSupport::TestCase
  setup do
    @original_clone_repo_method = Irida::PipelineRepository.method(:clone_repo)
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    @test_schema_body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json').read

    # Use a closure to capture @test_schema_body for the clone_repo implementation
    schema_body = @test_schema_body
    clone_repo_impl = lambda do |_uri, _sha, clone_dir|
      FileUtils.mkdir_p(clone_dir)
      File.write(File.join(clone_dir, 'nextflow_schema.json'), schema_body)

      # Create assets/schema_input.json
      FileUtils.mkdir_p(File.join(clone_dir, 'assets'))
      File.write(File.join(clone_dir, 'assets', 'schema_input.json'), schema_body)
      nil
    end

    Irida::PipelineRepository.singleton_class.send(:define_method, :clone_repo, clone_repo_impl)
  end

  teardown do
    Irida::PipelineRepository.singleton_class.send(:define_method, :clone_repo, @original_clone_repo_method)
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'pipelines with bad schema' do
    assert_raises Irida::Pipelines::PipelinesJsonFormatException do
      Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_bad_schema/pipelines.json',
                           pipeline_schema_file_dir: @pipeline_schema_file_dir)
    end
  end
end
