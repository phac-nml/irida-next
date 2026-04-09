# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'
require 'mocha/minitest'

class PipelinesTest < ActiveSupport::TestCase
  setup do
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
    # Pre-create the cached schema files so they exist before trying to fetch new ones
    schema_body = @test_schema_body
    cached_path = File.join(@pipeline_schema_file_dir, 'github.com/phac-nml/iridanextexample', '1.0.2')
    FileUtils.mkdir_p(File.join(cached_path, 'assets'))
    File.write(File.join(cached_path, 'nextflow_schema.json'), schema_body)
    File.write(File.join(cached_path, 'assets', 'schema_input.json'), schema_body)

    # Mock Rails.logger.error to capture the call
    Rails.logger.expects(:error).with('Pipeline phac-nml/iridanextexample_1.0.2 could not be updated').once

    # Override the mock to raise an exception for this test (simulating fetch failure)
    clone_repo_impl = lambda do |_uri, _sha, _clone_dir|
      raise Git::Error, 'Failed to clone'
    end

    Irida::PipelineRepository.singleton_class.send(:define_method, :clone_repo, clone_repo_impl)

    pipeline_refresh = Irida::Pipelines.new(
      pipeline_config_file: 'test/config/pipelines_fail_to_get_etag_for_cached_pipeline/pipelines.json',
      pipeline_schema_file_dir: @pipeline_schema_file_dir
    )

    pl = pipeline_refresh.pipelines['phac-nml/iridanextexample_1.0.2']
    assert_not_nil pl
    assert_not pl.executable

    # Restore the original mock
    clone_repo_impl_default = lambda do |_uri, _sha, clone_dir|
      FileUtils.mkdir_p(clone_dir)
      File.write(File.join(clone_dir, 'nextflow_schema.json'), schema_body)
      FileUtils.mkdir_p(File.join(clone_dir, 'assets'))
      File.write(File.join(clone_dir, 'assets', 'schema_input.json'), schema_body)
      nil
    end
    Irida::PipelineRepository.singleton_class.send(:define_method, :clone_repo, clone_repo_impl_default)
  end

  test 'raises exception and logs error on git repo not accessible' do
    # Mock Rails.logger.error to capture the call
    Rails.logger.expects(:error).with('Pipeline phac-nml/iridanextexample_1.0.2 could not be registered').once

    # Override the clone_repo to raise a 503 error
    clone_repo_impl = lambda do |_uri, _sha, _clone_dir|
      raise Irida::Pipelines::PipelinesInvalidUrlException.new('503', false)
    end

    Irida::PipelineRepository.singleton_class.send(:define_method, :clone_repo, clone_repo_impl)

    pipelines = Irida::Pipelines.new(
      pipeline_config_file: 'test/config/pipelines_fail_to_get_etag_for_cached_pipeline/pipelines.json',
      pipeline_schema_file_dir: @pipeline_schema_file_dir
    )

    # For non-cached, the pipeline should not be registered
    assert_nil pipelines.pipelines['phac-nml/iridanextexample_1.0.2']
  end
end
