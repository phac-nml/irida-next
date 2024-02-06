# frozen_string_literal: true

module Irida
  # Module to store pipeline values
  module Pipeline
    module_function

    def init(name = nil, id = nil, description = nil, version = nil, metadata = nil, type = nil,
             type_version = nil, engine = nil, engine_version = nil, url = nil, execute_loc = nil)

      workflow = Struct.new(:name, :id, :description, :version, :metadata, :type, :type_version, :engine,
      :engine_version, :url, :execute_loc)

      metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }

      @workflow = workflow.new(name, id, description, version, metadata, type, type_version, engine, engine_version, url, execute_loc)

      @workflow_schema = nil #JSON.parse(Rails.root.join("private/pipelines/#{name}/#{version}/nextflow_schema.json").read)
    end
  end
end
