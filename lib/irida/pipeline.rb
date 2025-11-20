# frozen_string_literal: true

module Irida
  # Class to store pipeline values
  class Pipeline # rubocop:disable Metrics/ClassLength
    attr_accessor :pipeline_id, :type, :type_version,
                  :engine, :engine_version, :url, :version, :schema_loc, :schema_input_loc, :automatable, :executable,
                  :default_params, :default_workflow_params

    IGNORED_PARAMS = %w[outdir email].freeze

    def initialize(pipeline_id, entry, version, schema_loc, schema_input_loc, unknown: false) # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists,Metrics/AbcSize
      @pipeline_id = pipeline_id
      @name = entry['name']
      @description = entry['description']
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
      @overrides = overrides_for_entry(entry, version)
      @samplesheet_schema_overrides_for_entry = samplesheet_schema_overrides_for_entry(entry, version)
      @default_params = default_params_for_entry
      @default_workflow_params = default_workflow_params_for_entry
      @unknown = unknown
    end

    def automatable?
      @automatable
    end

    def executable?
      @executable
    end

    def unknown?
      @unknown
    end

    def disabled?
      unknown? || !automatable? || !executable?
    end

    def name
      text_for(@name)
    end

    def description
      text_for(@description)
    end

    def workflow_params # rubocop:disable Metrics/AbcSize
      return {} if schema_loc.nil?

      nextflow_schema = JSON.parse(schema_loc.read)
      workflow_params = {}

      definitions = nextflow_schema['definitions'].deep_merge(@overrides['definitions'] || {})

      definitions.each do |key, definition|
        next unless show_section?(definition['properties'])

        key = key.to_sym

        workflow_params[key] =
          { title: text_for(definition['title']), description: text_for(definition['description']),
            properties: {} }

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

    def text_for(value)
      return '' if value.nil?

      if value.instance_of?(String)
        value
      else
        value[I18n.locale.to_s] || value[I18n.locale]
      end
    end

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

      processed_property[:description] = text_for(processed_property[:description])

      processed_property
    end

    def process_samplesheet_schema
      default_schema = JSON.parse(schema_input_loc.read)
      default_schema.deep_merge!(@samplesheet_schema_overrides_for_entry)
      default_schema
    end

    def show_section?(properties)
      properties.values.any? { |property| !property.key?('hidden') }
    end

    def overrides_for_entry(entry, version)
      overrides = entry['overrides'].deep_dup || {}

      overrides
        .deep_merge!(
          version.key?('overrides') ? version['overrides'] : {}
        )

      overrides
    end

    def samplesheet_schema_overrides_for_entry(entry, version)
      overrides = entry['samplesheet_schema_overrides'].deep_dup || {}
      version_overrides = version['samplesheet_schema_overrides'] || {}
      overrides.deep_merge!(version_overrides)
      overrides
    end

    def default_workflow_params_for_entry
      default_workflow_params = {}

      @overrides['definitions']&.each_value do |definition|
        next unless definition.key?('properties')

        definition['properties'].each do |name, property|
          property.each do |key, value|
            default_workflow_params.merge!({ name => value }) if key == 'default'
          end
        end
      end
      default_workflow_params
    end

    def default_params_for_entry
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
