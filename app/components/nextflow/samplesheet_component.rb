# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :samples, :required_properties, :metadata_fields, :namespace_id, :workflow_params

    FILE_CELL_TYPES = %w[fastq_cell file_cell].freeze

    def initialize(schema:, samples:, fields:, namespace_id:, workflow_params:)
      @samples = samples
      @namespace_id = namespace_id
      @metadata_fields = fields
      @required_properties = schema['items']['required'] || []
      @workflow_params = workflow_params
      extract_properties(schema)
    end

    def samples_workflow_executions_attributes
      samples.each_with_index.to_h do |sample, index|
        [index, samples_workflow_execution_attributes(sample)]
      end
    end

    private

    def samples_workflow_execution_attributes(sample)
      {
        sample_id: sample.id,
        samplesheet_params: sample_samplesheet_params(sample)
      }
    end

    def sample_samplesheet_params(sample) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      @properties.to_h do |name, property|
        case property['cell_type']
        when 'sample_cell'
          [name, sample.puid]
        when 'sample_name_cell'
          [name, sample.name]
        when 'fastq_cell'
          [name, ''] # TODO: set value to attachment id
        when 'file_cell'
          [name, ''] # TODO: set value to attachment id of file that matches regex
        when 'metadata_cell'
          [name, sample.metadata.fetch(name, '')]
        when 'dropdown_cell'
          [name, ''] # TODO: set to correct value
        when 'input_cell'
          [name, '']
        end
      end
    end

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @properties.each do |property, entry|
        @properties[property]['required'] = schema['items']['required'].include?(property)
        @properties[property]['cell_type'] = identify_cell_type(property, entry)
      end

      if @required_properties.include?('fastq_1') && @required_properties.include?('fastq_2')
        @properties['fastq_1']['pe_only'] = true
      end

      identify_autopopulated_file_properties
    end

    def identify_cell_type(property, entry)
      return 'sample_cell' if property == 'sample'

      return 'sample_name_cell' if property == 'sample_name'

      return 'fastq_cell' if property.match(/fastq_\d+/)

      return 'file_cell' if check_for_file(entry)

      return 'metadata_cell' if entry['meta'].present?

      return 'dropdown_cell' if entry['enum'].present?

      'input_cell'
    end

    def check_for_file(entry)
      entry['format'] == 'file-path' || (entry.key?('anyOf') && entry['anyOf'].any? do |e|
        e['format'] == 'file-path'
      end)
    end

    def identify_autopopulated_file_properties
      file_properties = @properties.select { |_property, entry| FILE_CELL_TYPES.include?(entry['cell_type']) }

      required_file_properties = file_properties.select { |_property, entry| entry['required'] }

      file_properties.each_key do |property|
        next unless required_file_properties.key?(property) ||
                    (required_file_properties.empty? && property == 'fastq_1')

        @properties[property]['autopopulate'] = true
      end
    end
  end
end
