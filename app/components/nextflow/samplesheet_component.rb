# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :samples, :required_properties, :metadata_fields, :namespace_id, :workflow_params,
                :patterns

    FILE_CELL_TYPES = %w[fastq_cell file_cell].freeze

    def initialize(schema:, samples:, fields:, namespace_id:, workflow_params:)
      @samples = samples
      @namespace_id = namespace_id
      @metadata_fields = fields
      @required_properties = schema['items']['required'] || []
      @workflow_params = workflow_params
      @patterns = {}
      extract_properties(schema)
    end

    def samples_workflow_executions_attributes
      attributes = samples.each_with_index.to_h do |sample, index|
        [index, samples_workflow_execution_attributes(sample)]
      end
      attributes.to_json
    end

    private

    def samples_workflow_execution_attributes(sample)
      {
        'sample_id' => sample.id,
        'samplesheet_params' => sample_samplesheet_params(sample),
        'patterns' => {}
      }
    end

    def sample_samplesheet_params(sample) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      @properties.to_h do |name, property|
        case property['cell_type']
        when 'sample_cell'
          [name, { form_value: sample.puid, cell_type: 'sample_cell', cell_value: sample.puid }]
        when 'sample_name_cell'
          [name, { form_value: sample.name, cell_type: 'sample_name_cell', cell_value: sample.name }]
        when 'fastq_cell'
          [name,
           file_samplesheet_values(sample.attachments.empty? ? nil : sample.most_recent_fastq_file(name,
                                                                                                   @workflow_params))]
        when 'file_cell'
          [name,
           file_samplesheet_values(sample.most_recent_other_file(property['autopopulate'], property['pattern']))]
        when 'metadata_cell'
          [name, metadata_samplesheet_values(sample, name)]
        when 'dropdown_cell' || 'input_cell'
          [name, { form_value: '', cell_type: property['cell_type'], cell_value: '' }]
        end
      end
    end

    def file_samplesheet_values(file)
      { form_value: file.empty? ? '' : file[:global_id],
        cell_type: 'file_cell',
        cell_value: file.empty? ? I18n.t('nextflow.samplesheet.file_cell_component.no_selected_file') : file[:filename],
        attachment_id: file.empty? ? '' : file[:id] }
    end

    def metadata_samplesheet_values(sample, name)
      metadata = sample.metadata.fetch(name, '')
      if metadata.empty?
        { form_value: '',
          cell_type: 'text',
          cell_value: nil }
      else
        { form_value: metadata,
          cell_type: 'metadata_cell',
          cell_value: metadata }
      end
    end

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @properties.each do |property, entry|
        @properties[property]['required'] = schema['items']['required'].include?(property)
        @properties[property]['cell_type'] = identify_cell_type(property, entry)
        if @properties[property]['pattern'] && %w[fastq_cell
                                                  file_cell].include?(@properties[property]['cell_type'])
          @patterns[property] = @properties[property]['pattern']
        end
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
