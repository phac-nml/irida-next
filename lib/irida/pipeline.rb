# frozen_string_literal: true

module Irida
  # Class to store pipeline values
  class Pipeline
    attr_accessor :name, :description, :metadata, :type, :type_version,
                  :engine, :engine_version, :url, :execute_loc,
                  :version, :schema_loc, :schema_input_loc

    def initialize(entry, version, schema_loc, schema_input_loc)
      @name = entry['name']
      @description = entry['description']
      @metadata = { workflow_name: name, workflow_version: version }
      @type = 'NFL'
      @type_version = 'DSL2'
      @engine = 'nextflow'
      @engine_version = '23.10.0'
      @url = entry['url']
      @execute_loc = 'azure'
      @version = version['name']
      @schema_loc = schema_loc
      @schema_input_loc = schema_input_loc
    end
  end
end
