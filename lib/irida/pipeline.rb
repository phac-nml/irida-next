# frozen_string_literal: true

module Irida
  # Module to store pipeline values
  module Pipeline
    module_function

    def init(entry, version, schema_loc, schema_input_loc)
      workflow = Struct.new(:name, :description, :version, :metadata, :type, :type_version, :engine,
                            :engine_version, :url, :execute_loc, :schema_loc, :schema_input_loc)

      name = entry['name']
      description = entry['description']
      metadata = { workflow_name: name, workflow_version: version }
      type = nil
      type_version = nil
      engine = nil
      engine_version = nil
      url = entry['url']
      execute_loc = 'azure'
      version = version['name']

      @workflow = workflow.new(name, description, version, metadata, type, type_version, engine, engine_version,
                               url, execute_loc, schema_loc, schema_input_loc)

      @workflow
    end
  end
end
