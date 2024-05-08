# frozen_string_literal: true

module Irida
  # Class to store pipeline values
  class Pipeline
    attr_accessor :name, :description, :metadata, :type, :type_version,
                  :engine, :engine_version, :url, :version, :schema_loc, :schema_input_loc, :automatable

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
      @version = version['name']
      @schema_loc = schema_loc
      @schema_input_loc = schema_input_loc
      @automatable = version['automatable'] || false
      @overrides = overrides_for_entry(entry)
    end

    def workflow_params
      nextflow_schema = JSON.parse(schema_loc.read)
      workflow_params = {}

      definitions = nextflow_schema['definitions'].deep_merge(@overrides['definitions'] || {})

      definitions.each do |key, definition|
        next unless show_section?(definition['properties'])

        key = key.to_sym

        workflow_params[key] = { title: definition['title'], description: definition['description'], properties: {} }

        workflow_params[key][:properties] = process_section(key, definition['properties'], definition['required'])
      end

      workflow_params
    end

    private

    def process_section(key, properties, required)
      processed_section = {}

      properties.each do |name, property|
        next unless !property['hidden'] && IGNORED_PARAMS.exclude?(name)

        name = name.to_sym

        processed_section[name] = process_property(key, name, property, required.present? && required.include?(name))
      end

      processed_section
    end

    def process_property(key, name, property, required)
      processed_property = property.clone.deep_symbolize_keys
      processed_property[:required] = required

      processed_property[:schema] = process_samplesheet_schema if key == :input_output_options && name == :input

      processed_property
    end

    def process_samplesheet_schema
      JSON.parse(schema_input_loc.read)
    end

    def show_section?(properties)
      properties.values.any? { |property| !property.key?('hidden') }
    end

    def overrides_for_entry(entry)
      return {} if entry['versions'].nil?

      overrides = entry['parameter_overrides'] || {}
      version_overrides = entry['versions'].find do |version|
        version['name'] == @version
      end || {}
      overrides
        .deep_merge(
          version_overrides.key?('parameter_overrides') ? version_overrides['parameter_overrides'] : {}
        )
    end
  end
end
