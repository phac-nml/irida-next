# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'uri'
require 'net/http'
require 'irida/pipeline'

module Irida
  # Module that reads a workflow config file and registers the available pipelines
  module Pipelines
    mattr_accessor :register_pipelines
    cattr_accessor :available_pipelines

    @@available_pipelines = [] # rubocop:disable Style/ClassVars

    module_function

    # Registers the available pipelines. This method is called
    # by an initializer which runs when the server is started up
    def register_pipelines
      data = read_json_config

      data.each do |entry|
        entry['versions'].each do |version|
          nextflow_schema_location = prepare_schema_download(entry, version, 'nextflow_schema')
          schema_input_location = prepare_schema_download(entry, version, 'schema_input')
          @@available_pipelines << Pipeline.init(entry, version, nextflow_schema_location, schema_input_location)
        end
      end
    end

    # read in the json config from config/pipelines/pipelines.json
    def read_json_config
      path = File.basename('pipelines.json')
      JSON.parse(Rails.root.join('config/pipelines/', path).read)
    end

    # Sets up the file names, paths, and urls to be used
    # by the write_schema_file method
    def prepare_schema_download(entry, version, type)
      filename = "#{type}.json"
      uri = URI.parse(entry['url'])
      pipeline_schema_files_path = "private/pipelines/#{uri.path}/#{version['name']}"

      if type == 'nextflow_schema'
        schema_file_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/#{filename}"
      elsif type == 'schema_input'
        schema_file_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/assets/#{filename}"
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
    def resource_etag_exists(resource_url, status_file_location, etag_type) # rubocop:disable Metrics/MethodLength
      status_file_location = Rails.root.join("#{status_file_location}/status.json")
      # File currently at pipeline url
      current_file_etag = resource_etag(resource_url)
      existing_etag = false

      if File.exist?(status_file_location)
        status_file = File.read(status_file_location)
        parsed_file = JSON.parse(status_file)
        existing_etag = parsed_file[etag_type] if parsed_file.key?(etag_type)

        return true if current_file_etag == existing_etag

        parsed_file[etag_type] = current_file_etag
        data_to_write = parsed_file
      else
        data_to_write = {}
        data_to_write[etag_type] = current_file_etag
      end

      File.open(status_file_location, 'w') { |output_file| output_file << data_to_write.to_json }
      false
    end

    # Get the etag from http.head which will be used to check if newer
    # schema files are required to be downloaded for a pipeline
    def resource_etag(resource_url) # rubocop:disable Metrics/AbcSize
      url = URI(resource_url)

      request_options = { use_ssl: url.scheme == 'https' }

      response = Net::HTTP.start(url.host, url.port, request_options) do |http|
        http.head(url.path).to_hash
      end

      # Handle Redirects
      if response['location']
        response_location = response['location'].join
        url = URI("#{url.scheme}://#{url.host}#{response_location}")

        response = Net::HTTP.start(url.host, url.port, request_options) do |http|
          http.head(url.path).to_hash
        end
      end

      response['etag'].join.scan(/"([^"]*)"/).join
    end
  end
end
