# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'uri'
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
          # schema_input_location = download_schema_input(entry, version)
          @@available_pipelines << Pipeline.init(entry, version, nextflow_schema_location)
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
      nextflow_schema_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/#{filename}"
      nextflow_schema_location =
        Rails.root.join("private/pipelines/#{uri.path}/#{version['name']}/#{filename}")

      dir = Rails.root.join("private/pipelines/#{uri.path}/#{version['name']}/#{filename}").dirname

      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      unless File.exist?("#{dir}/#{filename}")
        IO.copy_stream(URI.parse(nextflow_schema_url).open,
                       nextflow_schema_location)
      end

      nextflow_schema_location
    end

    def download_schema_input(entry, version)
      filename = 'schema_input.json'
      uri = URI.parse(entry['url'])
      schema_input_url = "https://raw.githubusercontent.com/#{uri.path}/#{version['name']}/assets/#{filename}"
      schema_input_location =
        Rails.root.join("private/pipelines/#{uri.path}/#{version['name']}/#{filename}")
      dir = Rails.root.join("private/pipelines/#{uri.path}/#{version['name']}/#{filename}").dirname
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      IO.copy_stream(URI.parse(schema_input_url).open, schema_input_location) unless File.exist?("#{dir}/#{filename}")

      schema_input_location
    end
  end
end
