# frozen_string_literal: true

module Irida
  # Class to store pipeline values
  class Pipeline # rubocop:disable Metrics/ClassLength
    attr_accessor :pipeline_id, :name, :description, :metadata, :type, :type_version,
                  :engine, :engine_version, :url, :version, :schema_loc, :schema_input_loc, :automatable, :executable,
                  :default_params, :default_workflow_params

    IGNORED_PARAMS = %w[outdir email].freeze

    def initialize(pipeline_id, entry, version, schema_loc, schema_input_loc, unknown: false) # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists,Metrics/AbcSize
      @pipeline_id = pipeline_id
      @name = entry['name']
      @description = entry['description']
      @metadata = { pipeline_id:, workflow_name: name, workflow_version: version }
      @type = 'NFL'
      @type_version = 'DSL2'
      @engine = 'nextflow'
      @engine_version = '23.10.0'
      @url = entry['url']
      @version = version['name']
      @schema_loc = schema_loc
      @schema_input_loc = schema_input_loc
      @automatable = version['automatable'].nil? ? false : version['automatable']
      @executable = version['executable'].nil? || version['executable']
      @overrides = overrides_for_entry(entry)
      @default_params = default_params_for_entry(entry)
      @default_workflow_params = default_workflow_params_for_entry(entry)
      @unknown = unknown
    end

    def automatable?
      @automatable == true
    end

    def executable?
      @executable == true
    end

    def unknown?
      @unknown == true
    end

    def workflow_params # rubocop:disable Metrics/AbcSize
      return {} if schema_loc.nil?

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

    def samplesheet_headers
      return [] if schema_input_loc.nil?

      sample_sheet = process_samplesheet_schema
      sample_sheet['items']['properties'].keys
    end

    def property_pattern(property_name)
      sample_sheet = process_samplesheet_schema
      sample_sheet['items']['properties'][property_name]['pattern']
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

      overrides = entry['overrides'] || {}
      version_overrides = entry['versions'].find do |version|
        version['name'] == @version
      end || {}
      overrides
        .deep_merge(
          version_overrides.key?('overrides') ? version_overrides['overrides'] : {}
        )
    end

    def default_workflow_params_for_entry(entry) # rubocop:disable Metrics/CyclomaticComplexity
      return {} if entry['versions'].nil?

      default_workflow_params = {}

      return default_workflow_params unless @overrides.key?('definitions')

      @overrides['definitions'].each_value do |definition|
        next unless definition.key?('properties')

        definition['properties'].each do |name, property|
          property.each do |key, value|
            default_workflow_params.merge!({ name => value }) if key == 'default'
          end
        end
      end
      default_workflow_params
    end

    def default_params_for_entry(entry)
      return {} if entry['versions'].nil?

      {
        workflow_type: @type,
        workflow_type_version: @type_version,
        workflow_engine: @engine,
        workflow_engine_version: @engine_version,
        workflow_url: @url,
        workflow_engine_parameters: { '-r': @version }
      }
    end
  end
end
