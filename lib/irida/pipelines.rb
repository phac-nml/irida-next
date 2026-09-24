# frozen_string_literal: true

require 'json'
require 'uri'
require 'git'
require 'tmpdir'
require 'tempfile'
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
      @pipeline_repo_dir = params.fetch(:pipeline_repo_dir, 'private/pipeline_repos')
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
      schema_locations = schema_store.mirror_and_prepare_schema_locations(uri, version)

      Pipeline.new(pipeline_id, entry, version, *schema_locations)
    rescue JSON::ParserError => e
      log_pipeline_error(pipeline_id, version, "has invalid schema JSON: #{e.message}")
      non_executable_pipeline(pipeline_id, entry, version)
    rescue PipelinesInvalidUrlException => e
      handle_invalid_url(e, pipeline_id, entry, version)
    end

    # Marks a pipeline as non executable when its schema could not be updated,
    # otherwise skips registration entirely for a never-fetched pipeline.
    def handle_invalid_url(error, pipeline_id, entry, version)
      if error.previously_fetched
        log_pipeline_error(pipeline_id, version, 'could not be updated')
        non_executable_pipeline(pipeline_id, entry, version)
      else
        log_pipeline_error(pipeline_id, version, 'could not be registered')
        nil
      end
    end

    def non_executable_pipeline(pipeline_id, entry, version)
      version['executable'] = false
      Pipeline.new(pipeline_id, entry, version, nil, nil)
    end

    def log_pipeline_error(pipeline_id, version, message)
      Rails.logger.error("Pipeline #{pipeline_id}_#{version['name']} #{message}")
    end

    # read in the json pipeline config
    def read_json_config
      path = @pipeline_config_file
      data = JSON.parse(Rails.root.join(path).read)

      errors = JSONSchemer.schema(PIPELINES_JSON_SCHEMA.read).validate(data).to_a

      raise PipelinesJsonFormatException, "Exception parsing #{path}: #{errors}" unless errors.empty?

      data
    end

    def schema_store
      @schema_store ||= PipelineSchemaStore.new(
        schema_file_dir: @pipeline_schema_file_dir,
        repo_dir: @pipeline_repo_dir
      )
    end
  end

  # Mirrors pipeline git repositories and writes their schema files to disk,
  # keeping repository I/O separate from pipeline registration.
  class PipelineSchemaStore
    def initialize(schema_file_dir:, repo_dir:)
      @schema_file_dir = schema_file_dir
      @repo_dir = repo_dir
    end

    # Returns [nextflow_schema_location, schema_input_location].
    # Raises Pipelines::PipelinesInvalidUrlException when the repo is unreachable.
    def mirror_and_prepare_schema_locations(uri, version)
      pipeline_repo = PipelineRepository.mirror_repo(uri, repo_dir_for(uri))

      [
        copy_schema_file(pipeline_repo, uri, version, 'nextflow_schema'),
        copy_schema_file(pipeline_repo, uri, version, 'schema_input')
      ]
    rescue Git::Error => e
      raise Pipelines::PipelinesInvalidUrlException.new('404', schema_files_exist?(uri, version)), e.message
    end

    private

    def repo_dir_for(uri)
      path = uri.path.sub(%r{\A/}, '')
      path += '.git' unless path.end_with?('.git')

      Rails.root.join(@repo_dir, path)
    end

    def schema_files_exist?(uri, version)
      schema_path = File.join(@schema_file_dir, uri.path.sub(%r{\A/}, ''), version['name'])
      File.exist?(File.join(schema_path, 'nextflow_schema.json')) ||
        File.exist?(File.join(schema_path, 'assets', 'schema_input.json'))
    end

    def copy_schema_file(repo, uri, version, type)
      filename = type == 'nextflow_schema' ? "#{type}.json" : "assets/#{type}.json"
      contents = repo.file_contents_at(version['name'], filename)

      schema_path = File.join(@schema_file_dir, uri.path.sub(%r{\A/}, ''), version['name'])
      schema_location = Rails.root.join(schema_path, filename)

      write_schema_file(contents, schema_location)
      schema_location
    end

    def write_schema_file(contents, schema_location)
      dir = File.dirname(schema_location)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      Tempfile.create(['schema', '.json'], dir) do |tmpfile|
        tmpfile.binmode
        tmpfile.write(contents.to_s)
        tmpfile.flush
        tmpfile.fsync
        FileUtils.mv(tmpfile.path, schema_location)
      end
    end
  end
end
