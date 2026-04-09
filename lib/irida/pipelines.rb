# frozen_string_literal: true

require 'json'
require 'uri'
require 'git'
require 'tmpdir'
require 'irida/pipeline'
require 'irida/pipeline_repository'

module Irida
  # Class that reads a workflow config file and registers the available pipelines
  class Pipelines
    class PipelinesJsonFormatException < StandardError
    end

    class PipelinesInvalidUrlException < StandardError # rubocop:disable Style/Documentation
      attr_reader :code, :previously_fetched

      def initialize(code, previously_fetched) # rubocop:disable Lint/MissingSuper
        @code = code
        @previously_fetched = previously_fetched
      end
    end
    PIPELINES_JSON_SCHEMA = Rails.root.join('config/schemas/pipelines_schema.json')
    UNKNOWN_PIPELINE_ENTRY = { 'name' => 'UNKNOWN WORKFLOW', 'description' => 'UNKNOWN WORKFLOW' }.freeze
    UNKNOWN_PIPELINE_VERSION = { 'executable' => false }.freeze

    class_attribute :instance

    def initialize(**params)
      @pipeline_config_file = params.fetch(:pipeline_config_file, 'config/pipelines/pipelines.json')
      @pipeline_schema_file_dir = params.fetch(:pipeline_schema_file_dir, 'private/pipelines')
      @pipelines = {}

      register_pipelines
    end

    def pipelines(type = 'available')
      case type
      when 'executable'
        @pipelines.select { |_key, pipeline| pipeline.executable? }
      when 'automatable'
        @pipelines.select { |_key, pipeline| pipeline.automatable? && pipeline.executable? }
      else
        @pipelines
      end
    end

    def find_pipeline_by(pipeline_id, version)
      pipeline = @pipelines["#{pipeline_id}_#{version}"]

      return pipeline unless pipeline.nil?

      Pipeline.new(pipeline_id,
                   UNKNOWN_PIPELINE_ENTRY,
                   { 'name' => version }.merge(UNKNOWN_PIPELINE_VERSION),
                   nil,
                   nil,
                   unknown: true)
    end

    private

    # Registers the available pipelines. This method is called
    # by an initializer which runs when the server is started up
    def register_pipelines
      data = read_json_config

      data.each do |pipeline_id, entry|
        entry['versions'].each do |version|
          next if @pipelines.key?("#{pipeline_id}_#{version['name']}")

          pipeline = create_pipeline(pipeline_id, entry, version)
          @pipelines["#{pipeline_id}_#{version['name']}"] = pipeline unless pipeline.nil?
        end
      end
    end

    def create_pipeline(pipeline_id, entry, version)
      uri = URI.parse(entry['url'])
      nextflow_schema_location, schema_input_location = clone_and_prepare_schema_locations(uri, version)

      Pipeline.new(pipeline_id, entry, version, nextflow_schema_location, schema_input_location)
    rescue PipelinesInvalidUrlException => e
      raise e if e.code == '503' # re-raise error to force crash

      if e.previously_fetched # log error and mark pipeline as non executable
        Rails.logger.error("Pipeline #{pipeline_id}_#{version['name']} could not be updated")
        version['executable'] = false
        Pipeline.new(pipeline_id, entry, version, nil, nil)
      else # log error and skip this pipeline
        Rails.logger.error("Pipeline #{pipeline_id}_#{version['name']} could not be registered")
        nil
      end
    end

    def clone_and_prepare_schema_locations(uri, version)
      nextflow_schema_location = nil
      schema_input_location = nil

      Dir.mktmpdir('irida_pipeline') do |clone_dir|
        PipelineRepository.clone_repo(uri, version['name'], clone_dir)
        nextflow_schema_location = copy_schema_file(clone_dir, uri, version, 'nextflow_schema')
        schema_input_location = copy_schema_file(clone_dir, uri, version, 'schema_input')
      end

      [nextflow_schema_location, schema_input_location]
    end

    # read in the json pipeline config
    def read_json_config
      path = @pipeline_config_file
      data = JSON.parse(Rails.root.join(path).read)

      errors = JSONSchemer.schema(PIPELINES_JSON_SCHEMA.read).validate(data).to_a

      raise PipelinesJsonFormatException, "Exception parsing #{path}: #{errors}" unless errors.empty?

      data
    end

    def copy_schema_file(clone_dir, uri, version, type)
      filename = type == 'nextflow_schema' ? "#{type}.json" : "assets/#{type}.json"
      source_path = File.join(clone_dir, filename)

      pipeline_schema_files_path = File.join(@pipeline_schema_file_dir, uri.path, version['name'])
      schema_location = Rails.root.join(pipeline_schema_files_path, filename)

      write_schema_file(source_path, schema_location)
      schema_location
    end

    def write_schema_file(source_path, schema_location)
      dir = File.dirname(schema_location)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      FileUtils.cp(source_path, schema_location)
    end
  end
end
