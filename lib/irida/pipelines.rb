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

    def register_pipelines
      data = read_json_config

      data.each do |entry|
        entry['versions'].each do |version|
          nextflow_schema_location = download_nextflow_schema(entry, version)
          schema_input_location = download_schema_input(entry, version)
          @@available_pipelines << Pipeline.init(entry, version, nextflow_schema_location, schema_input_location)
        end
      end
    end

    # read in the json config from config/pipelines/pipelines.json
    def read_json_config
      path = File.basename('pipelines.json')
      JSON.parse(Rails.root.join('config/pipelines/', path).read)
    end

    def download_nextflow_schema(entry, version)
      filename = 'nextflow_schema.json'
      uri = URI.parse(entry['url'])
      pipeline_schema_files_path = "private/pipelines/#{uri.path}/#{version['name']}"
      nextflow_schema_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/#{filename}"
      nextflow_schema_location =
        Rails.root.join("#{pipeline_schema_files_path}/#{filename}")

      dir = Rails.root.join("#{pipeline_schema_files_path}/#{filename}").dirname

      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      unless resource_etag_exists(nextflow_schema_url, pipeline_schema_files_path, 'nextflow_schema')
        IO.copy_stream(URI.parse(nextflow_schema_url).open,
                       nextflow_schema_location)
      end

      nextflow_schema_location
    end

    def download_schema_input(entry, version)
      filename = 'schema_input.json'
      uri = URI.parse(entry['url'])
      pipeline_schema_files_path = "private/pipelines/#{uri.path}/#{version['name']}"
      schema_input_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/assets/#{filename}"
      schema_input_location =
        Rails.root.join("#{pipeline_schema_files_path}/#{filename}")
      dir = Rails.root.join("#{pipeline_schema_files_path}/#{filename}").dirname
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      unless resource_etag_exists(schema_input_url, pipeline_schema_files_path, 'schema_input')
        IO.copy_stream(URI.parse(schema_input_url).open, schema_input_location)
      end

      schema_input_location
    end

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
