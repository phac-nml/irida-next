# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'uri'
require 'net/http'
require 'irida/pipeline'

module Irida
  # Class that reads a workflow config file and registers the available pipelines
  class Pipelines
    PipelinesJsonFormatException = Class.new StandardError
    PIPELINES_JSON_SCHEMA = Rails.root.join('config/schemas/pipelines_schema.json')

    class_attribute :instance


    def initialize(**params)
      @pipeline_config_dir = params.key?(:pipeline_config_dir) ? params[:pipeline_config_dir] : 'config/pipelines'
      @pipeline_schema_file_dir = params.key?(:pipeline_schema_file_dir) ? params[:pipeline_schema_file_dir] : 'private/pipelines'
      @pipeline_config_file = params.key?(:pipeline_config_file) ? params[:pipeline_config_file] : 'pipelines.json'
      @pipeline_schema_status_file = params.key?(:pipeline_schema_status_file) ? params[:pipeline_schema_status_file] : 'status.json'
      @available_pipelines = {}
      @automatable_pipelines = {}

      register_pipelines
    end

    # Registers the available pipelines. This method is called
    # by an initializer which runs when the server is started up
    def register_pipelines
      data = read_json_config

      data.each do |entry|
        entry['versions'].each do |version|
          next if @available_pipelines.key?("#{entry['name']}_#{version['name']}")

          nextflow_schema_location = prepare_schema_download(entry, version, 'nextflow_schema')
          schema_input_location = prepare_schema_download(entry, version, 'schema_input')

          pipeline = Pipeline.new(entry, version, nextflow_schema_location, schema_input_location)
          @available_pipelines["#{entry['name']}_#{version['name']}"] = pipeline
          @automatable_pipelines["#{entry['name']}_#{version['name']}"] = pipeline if version['automatable']
        end
      end
      @initialized = true
    end

    # read in the json pipeline config
    def read_json_config
      path = File.basename(@pipeline_config_file)
      data = JSON.parse(Rails.root.join(@pipeline_config_dir, path).read)

      errors = JSONSchemer.schema(PIPELINES_JSON_SCHEMA.read).validate(data).to_a

      raise PipelinesJsonFormatException, "Exception parsing #{path}: #{errors}" unless errors.empty?

      data
    end

    # Sets up the file names, paths, and urls to be used
    # by the write_schema_file method
    def prepare_schema_download(entry, version, type)
      filename = "#{type}.json"
      uri = URI.parse(entry['url'])
      pipeline_schema_files_path = "#{@pipeline_schema_file_dir}/#{uri.path}/#{version['name']}"

      schema_file_url = if type == 'nextflow_schema'
                          "https://raw.githubusercontent.com#{uri.path}/#{version['name']}/#{filename}"
                        else
                          "https://raw.githubusercontent.com#{uri.path}/#{version['name']}/assets/#{filename}"
                        end

      schema_location =
        Rails.root.join("#{pipeline_schema_files_path}/#{filename}")

      write_schema_file(schema_file_url, schema_location, pipeline_schema_files_path, filename, type)

      schema_location
    end

    # Create directory if it doesn't exist and write the schema file unless the resource etag matches
    # the currently stored resource etag
    def write_schema_file(schema_file_url, schema_location, pipeline_schema_files_path, filename, type)
      dir = Rails.root.join("#{pipeline_schema_files_path}/#{filename}").dirname
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      return if resource_etag_exists(schema_file_url, pipeline_schema_files_path, type)

      IO.copy_stream(URI.parse(schema_file_url).open, schema_location)
    end

    # Checks if the current local stored resource etag matches the etag of
    # the resource at the url. If not we overwrite the existing etag for the
    # local stored file, otherwise we just write the new etag to the status.json
    # file
    def resource_etag_exists(resource_url, status_file_location, etag_type)
      status_file_location = Rails.root.join("#{status_file_location}/#{@pipeline_schema_status_file}")
      # File currently at pipeline url
      current_file_etag = resource_etag(resource_url)
      existing_etag = false
      data = {}

      if File.exist?(status_file_location)
        status_file = File.read(status_file_location)
        data = JSON.parse(status_file)
        existing_etag = data[etag_type] if data.key?(etag_type) && data[etag_type].present?

        return true if current_file_etag == existing_etag
      end

      data[etag_type] = current_file_etag

      File.open(status_file_location, 'w') { |output_file| output_file << data.to_json }
      false
    end

    # Get the etag from headers which will be used to check if newer
    # schema files are required to be downloaded for a pipeline
    def resource_etag(resource_url)
      url = URI(resource_url)
      headers = retrieve_headers(url)

      # Handle Redirects
      if headers['location']
        response_location = headers['location'].join
        url = URI("#{url.scheme}://#{url.host}#{response_location}")

        headers = retrieve_headers(url)
      end

      headers['etag'].join.scan(/"([^"]*)"/).join
    end

    # Get the headers for the resource
    def retrieve_headers(url)
      request_options = { use_ssl: url.scheme == 'https' }
      Net::HTTP.start(url.host, url.port, request_options) do |http|
        http.head(url.path).to_hash
      end
    end

    def find_pipeline_by(name, version)
      @available_pipelines["#{name}_#{version}"]
    end

    def available_pipelines
      @available_pipelines
    end

    def pipeline_config_dir=(dir)
      @pipeline_config_dir = dir
    end

    def pipeline_schema_file_dir=(dir)
      @pipeline_schema_file_dir = dir
    end

    def automatable_pipelines
      @automatable_pipelines
    end

    # If the pipelines have been initialized or not for the current process
    def initialized
      @initialized
    end
  end
end
