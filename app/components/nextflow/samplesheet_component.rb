# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component # rubocop:disable Metrics/ClassLength
    attr_reader :properties, :samples, :required_properties, :metadata_fields, :namespace_id, :workflow_params

    FILE_CELL_TYPES = %w[fastq_cell file_cell].freeze

    def initialize(schema:, samples:, fields:, namespace_id:, workflow_params:)
      @samples = samples
      @namespace_id = namespace_id
      @metadata_fields = fields
      @required_properties = schema['items']['required'] || []
      @workflow_params = workflow_params
      @file_attributes = {}
      extract_properties(schema)
    end

    def samples_workflow_executions_attributes
      samples.each_with_index.to_h do |sample|
        [sample.id, samples_workflow_execution_attributes(sample)]
      end
    end

    private

    def samples_workflow_execution_attributes(sample)
      sample_attributes = {
        'sample_id' => sample.id,
        'samplesheet_params' => sample_samplesheet_params(sample)
      }
      unless @properties.key?('fastq_1') && @properties.key?('fastq_2') && !sample.attachments.empty?
        return sample_attributes
      end

      fastq_file_attributes = sample.most_recent_fastq_files
      sample_attributes['samplesheet_params'].merge(fastq_file_samplesheet_values(fastq_file_attributes,
                                                                                  sample.id))
      sample_attributes
    end

    def sample_samplesheet_params(sample) # rubocop:disable Metrics/MethodLength
      @properties.to_h do |name, property|
        case property['cell_type']
        when 'sample_cell'
          [name, sample.puid]
        when 'sample_name_cell'
          [name, sample.name]
        when 'file_cell'
          [name,
           file_samplesheet_values(
             sample.most_recent_other_file(property['autopopulate'], property['pattern']), sample.id, name
           )]
        when 'metadata_cell'
          [name, metadata_samplesheet_values(sample, name, property)]
        when 'dropdown_cell', 'input_cell', 'fastq_cell'
          # fastq is queried above in samples_workflow_execution_attributes and values are merged over this empty value
          [name, '']
        end
      end
    end

    def expected_pattern(entry)
      if entry.key?('pattern')
        entry['pattern']
      elsif entry.key?('anyOf')
        entry['anyOf'].select do |condition|
          condition.key?('pattern')
        end.pluck('pattern').join('|')
      end
    end

    def file_samplesheet_values(file, sample_id, column_name)
      @file_attributes[sample_id] = {} unless @file_attributes.key?(sample_id)
      @file_attributes[sample_id][column_name] = {
        filename: if file.empty?
                    I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
                  else
                    file[:filename]
                  end,
        attachment_id: file.empty? ? '' : file[:id]
      }
      file.empty? ? '' : file[:global_id]
    end

    def fastq_file_samplesheet_values(files, sample_id)
      fastq_samplesheet_params = {}
      files.each do |name, file|
        fastq_samplesheet_params[name] = file_samplesheet_values(file, sample_id, name)
      end
      fastq_samplesheet_params
    end

    def metadata_samplesheet_values(sample, name, property)
      metadata = sample.metadata.fetch(property.fetch('x-irida-next-selected', name), '')
      metadata.empty? ? '' : metadata
    end

    def extract_properties(schema) # rubocop:disable Metrics/AbcSize
      @properties = schema['items']['properties']
      @properties.each do |property, entry|
        @properties[property]['required'] = schema['items']['required'].include?(property)
        @properties[property]['cell_type'] = identify_cell_type(property, entry)
        @properties[property]['pattern'] = expected_pattern(entry)
      end

      if @required_properties.include?('fastq_1') && @required_properties.include?('fastq_2')
        @properties['fastq_1']['pe_only'] = true
      end
      identify_autopopulated_file_properties
    end

    def identify_cell_type(property, entry)
      return 'sample_cell' if property == 'sample'

      return 'sample_name_cell' if property == 'sample_name'

      return 'fastq_cell' if property.match(/^fastq_\d+$/)

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
