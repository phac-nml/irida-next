# frozen_string_literal: true

module Irida
  # Module to store pipeline values
  module Pipeline
    module_function

    def init(name = nil, id = nil, description = nil, version = nil, type = nil, # rubocop:disable Metrics/ParameterLists
             type_version = nil, engine = nil, engine_version = nil, url = nil, execute_loc = nil, schema_loc = nil)

      workflow = Struct.new(:name, :id, :description, :version, :metadata, :type, :type_version, :engine,
                            :engine_version, :url, :execute_loc, :schema_loc)

      metadata = { workflow_name: name, workflow_version: version }

      @workflow = workflow.new(name, id, description, version, metadata, type, type_version, engine, engine_version,
                               url, execute_loc, schema_loc)

      @workflow
    end
  end
end
