# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'uri'
require 'net/http'
require 'irida/pipeline'

module Irida
  # Class that reads a workflow config file and registers the available pipelines
  class Pipelines # rubocop:disable Metrics/ClassLength
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
    UNKNOWN_PIPELINE_ENTRY = {
      'name' => 'UNKNOWN WORKFLOW',
      'description' => 'UNKNOWN WORKFLOW'
    }.freeze
    UNKNOWN_PIPELINE_VERSION = {
      'executable' => false
    }.freeze

    class_attribute :instance

    def initialize(**params)
      @pipeline_config_file = params.fetch(:pipeline_config_file, 'config/pipelines/pipelines.json')
      @pipeline_schema_file_dir = params.fetch(:pipeline_schema_file_dir, 'private/pipelines')
      @pipeline_schema_status_file = params.fetch(:pipeline_schema_status_file, 'status.json')
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
      uri = get_uri_from_entry(entry, pipeline_id)
      nextflow_schema_location = prepare_schema_download(uri, version, 'nextflow_schema')
      schema_input_location = prepare_schema_download(uri, version, 'schema_input')

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

    # read in the json pipeline config
    def read_json_config
      path = @pipeline_config_file
      data = JSON.parse(Rails.root.join(path).read)

      errors = JSONSchemer.schema(PIPELINES_JSON_SCHEMA.read).validate(data).to_a

      raise PipelinesJsonFormatException, "Exception parsing #{path}: #{errors}" unless errors.empty?

      data
    end

    def get_uri_from_entry(entry, pipeline_id)
      uri = URI.parse(entry['url'])

      unless uri.scheme == 'https' && uri.host == 'github.com'
        Rails.logger.warn("Pipeline with id '#{pipeline_id}' specifies a url not hosted on 'https://github.com'")
      end

      uri
    end

    # Sets up the file names, paths, and urls to be used
    # by the write_schema_file method
    def prepare_schema_download(uri, version, type)
      filename = "#{type}.json"

      pipeline_schema_files_path = File.join(@pipeline_schema_file_dir, uri.path, version['name'])

      schema_file_url = if type == 'nextflow_schema'
                          "https://raw.githubusercontent.com#{uri.path}/#{version['name']}/#{filename}"
                        else
                          "https://raw.githubusercontent.com#{uri.path}/#{version['name']}/assets/#{filename}"
                        end

      schema_location =
        Rails.root.join(pipeline_schema_files_path, filename)

      write_schema_file(schema_file_url, schema_location, pipeline_schema_files_path, type)

      schema_location
    end

    # Create directory if it doesn't exist and write the schema file unless the resource etag matches
    # the currently stored resource etag
    def write_schema_file(schema_file_url, schema_location, pipeline_schema_files_path, type)
      dir = Rails.root.join(pipeline_schema_files_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      return if resource_etag_exists(schema_file_url, pipeline_schema_files_path, type)

      IO.copy_stream(URI.parse(schema_file_url).open, schema_location)
    end

    # Checks if the current local stored resource etag matches the etag of
    # the resource at the url. If not we overwrite the existing etag for the
    # local stored file, otherwise we just write the new etag to the status.json
    # file
    def resource_etag_exists(resource_url, status_file_location, etag_type) # rubocop:disable Naming/PredicateMethod
      status_file_location = Rails.root.join(status_file_location, @pipeline_schema_status_file)

      # File etag if it currently exists, nil otherwise
      existing_etag = get_existing_etag(status_file_location, etag_type)
      # File currently at pipeline url
      current_file_etag = fetch_resource_etag(resource_url, !existing_etag.nil?)

      return true if current_file_etag == existing_etag

      update_status_file(status_file_location, { etag_type.to_s => current_file_etag })
      false
    end

    def update_status_file(status_file_location, new_data)
      if File.exist?(status_file_location)
        status_file = File.read(status_file_location)
        data = JSON.parse(status_file)
        data_to_write = data.merge(new_data).to_json
      else
        data_to_write = new_data.to_json
      end

      File.open(status_file_location, 'w') { |output_file| output_file << data_to_write }
    end

    # File etag if it currently exists, false otherwise
    def get_existing_etag(status_file_location, etag_type)
      if File.exist?(status_file_location)
        status_file = File.read(status_file_location)
        data = JSON.parse(status_file)
        return data[etag_type] if data.key?(etag_type) && data[etag_type].present?
      end
      nil
    end

    # Get the etag from headers which will be used to check if newer
    # schema files are required to be downloaded for a pipeline
    def fetch_resource_etag(resource_url, previously_fetched)
      url = URI(resource_url)
      headers = retrieve_headers(url, previously_fetched)

      # Handle Redirects
      if headers['location']
        response_location = headers['location'].join
        url = URI("#{url.scheme}://#{url.host}#{response_location}")

        headers = retrieve_headers(url, previously_fetched)
      end

      headers['etag'].join.scan(/"([^"]*)"/).join
    end

    # Get the headers for the resource
    def retrieve_headers(url, previously_fetched)
      request_options = { use_ssl: url.scheme == 'https' }
      Net::HTTP.start(url.host, url.port, request_options) do |http|
        resp = http.head(url.path)

        unless resp.code == '200'
          message = "Schema url `#{url.path}` returned http `#{resp.code}`. Previously fetched successfully: #{previously_fetched}" # rubocop:disable Layout/LineLength
          Rails.logger.error(message)
          raise PipelinesInvalidUrlException.new(resp.code, previously_fetched), message
        end

        resp.to_hash
      end
    end
  end
end
