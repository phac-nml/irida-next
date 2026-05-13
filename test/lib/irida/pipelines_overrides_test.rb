# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'
require 'mocha/minitest'

class PipelinesOverrides < ActiveSupport::TestCase
  setup do
    @original_mirror_repo_method = Irida::PipelineRepository.method(:mirror_repo)
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"

    # Read in schema file to json
    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json').read
    nextflow_fastmatch_body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema_fastmatch.json').read
    nextflow_samplesheet_fastmatch_body = Rails.root.join(
      'test/fixtures/files/nextflow/samplesheet_schema_fastmatch.json'
    ).read

    file_contents_at_impl = lambda do |sha, path|
      if ['2.0.2', '2.0.1', '2.0.0'].include?(sha)
        # iridanextexample
        body
      elsif ['0.4.1', '0.4.0'].include?(sha)
        # fastmatchirida
        if path == 'nextflow_schema.json'
          nextflow_fastmatch_body
        elsif path == 'assets/schema_input.json'
          nextflow_samplesheet_fastmatch_body
        else
          ''
        end
      end
    end

    # Mock mirror_repo to simulate Git operations
    clone_repo_impl = lambda do |_uri, repo_dir|
      FileUtils.mkdir_p(repo_dir)

      Object.new.tap do |repo|
        repo.define_singleton_method(:file_contents_at, file_contents_at_impl)
      end
    end

    Irida::PipelineRepository.singleton_class.send(:define_method, :mirror_repo, clone_repo_impl)
  end

  teardown do
    FileUtils.remove_dir(@pipeline_schema_file_dir, true)
    Irida::PipelineRepository.singleton_class.send(:define_method, :mirror_repo, @original_mirror_repo_method)
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
    workflow2 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.0')

    # rubocop:disable Layout/LineLength
    assert_equal 'new_isolates_date',
                 workflow1.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_1']['x-irida-next-selected']

    assert_equal 'predicted_primary_identification_name',
                 workflow1.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_2']['x-irida-next-selected']

    assert_equal 'new_isolates_date',
                 workflow2.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_1']['x-irida-next-selected']

    # Workflow2 has an entry level override which overrides ["metadata_2"]["x-irida-next-selected"]
    assert_not_equal 'predicted_primary_identification_name',
                     workflow2.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_2']['x-irida-next-selected']
    # rubocop:enable Layout/LineLength
  end

  test 'pipelines with samplesheet overrides at version level' do
    pipelines = Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines_with_overrides/pipelines.json',
                                     pipeline_schema_file_dir: @pipeline_schema_file_dir)

    workflow1 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.1')
    workflow2 = pipelines.find_pipeline_by('PNC Fast Match', '0.4.0')

    # rubocop:disable Layout/LineLength
    assert_equal 'new_isolates_date',
                 workflow1.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_1']['x-irida-next-selected']

    assert_equal 'predicted_primary_identification_name',
                 workflow1.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_2']['x-irida-next-selected']

    assert_equal 'new_isolates_date',
                 workflow2.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_1']['x-irida-next-selected']

    assert_equal 'overridden_metadata_field',
                 workflow2.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']['metadata_2']['x-irida-next-selected']
    # rubocop:enable Layout/LineLength
  end
end
