# frozen_string_literal: true

require "json"
require 'irida/pipeline'

module Irida
  # Module to store pipeline values
  module Pipelines
    mattr_accessor :register_pipelines
    attr_accessor :workflows

    module_function

    def register_pipelines
      puts "REGISTERING PIPELINES"
      @workflows = []
      # Read config/pipelines/pipelines.json and loop through the entries
      data = read_json_config

      data.each_with_index do |entry, index|
        entry['versions'].each do |version|
          # 1) For each entry download the nextflow_schema.json file for the pipeline
            # Get file from https://raw.githubusercontent.com/:organization/:repo/:name/nextflow_schema.json
          # 2) Save file to to private/pipelines/:name/:version/nextflow_schema.json
          # 2) Get file from https://raw.githubusercontent.com/:organization/:repo/:name/assets/schema_input.json
          # 3) Save file to to private/pipelines/:name/:version/assets/schema_input.json
          @workflows << Pipeline.init(entry['name'], index+1, entry['description'], version['name'], nil, nil, nil, nil, nil, entry['url'], "azure" )
        end
      end
      puts @workflows.inspect
      @workflows
    end

    # read in the json config from config/pipelines/pipelines.json
    def read_json_config
      path = File.basename("pipelines.json")
      JSON.parse(Rails.root.join("config/pipelines/", path).read)
    end
  end
end
