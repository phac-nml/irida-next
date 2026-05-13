# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class PipelinesSchemaTest < ActiveSupport::TestCase
  setup do
    @original_mirror_repo_method = Irida::PipelineRepository.method(:mirror_repo)
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    test_schema_body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json').read

    file_contents_at_impl = lambda do |_sha, _path|
      test_schema_body
    end

    clone_repo_impl = lambda do |_uri, _repo_dir|
      Object.new.tap do |repo|
        repo.define_singleton_method(:file_contents_at, file_contents_at_impl)
      end
    end

    Irida::PipelineRepository.singleton_class.send(:define_method, :mirror_repo, clone_repo_impl)
  end

  teardown do
    Irida::PipelineRepository.singleton_class.send(:define_method, :mirror_repo, @original_mirror_repo_method)
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
  end

  test 'pipelines with bad schema' do
    assert_raises Irida::Pipelines::PipelinesJsonFormatException do
      Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_bad_schema/pipelines.json',
                           pipeline_schema_file_dir: @pipeline_schema_file_dir)
    end
  end
end
