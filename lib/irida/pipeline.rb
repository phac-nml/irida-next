# frozen_string_literal: true

module Irida
  # Class to store pipeline values
  class Pipeline
    attr_accessor :name, :description, :metadata, :type, :type_version,
                  :engine, :engine_version, :url, :execute_loc,
                  :version, :schema_loc, :schema_input_loc

    IGNORED_PARAMS = %w[outdir email].freeze

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

    def workflow_params # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      nextflow_schema = JSON.parse(schema_loc.read)
      workflow_params = {}

      nextflow_schema['definitions'].each do |key, definition|
        next unless show_section?(definition['properties'])

        workflow_params[key] = { title: definition['title'], description: definition['description'], properties: {} }

        definition['properties'].each do |name, property|
          next unless !property['hidden'] && IGNORED_PARAMS.exclude?(name)

          workflow_params[key][:properties][name] = property.clone
          workflow_params[key][:properties][name]['required'] =
            definition['required'].present? && definition['required'].include?(name)

          next unless key == 'input_output_options' && name == 'input'

          workflow_params[key][:properties][name]['schema'] = schema_input_loc
        end
      end

      workflow_params
    end

    private

    def show_section?(properties)
      properties.values.any? { |property| !property.key?('hidden') }
    end
  end
end
