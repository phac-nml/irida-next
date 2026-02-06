# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table for feature flag :deferred_samplesheet
  class DeferredSamplesheetComponent < Component
    attr_reader :properties, :required_properties, :metadata_fields, :namespace_id, :workflow_params

    FILE_CELL_TYPES = %w[fastq_cell file_cell].freeze

    def initialize(schema:, fields:, namespace_id:, workflow_params:)
      @namespace_id = namespace_id
      @metadata_fields = fields
      @required_properties = schema['items']['required'] || []
      @workflow_params = workflow_params
      extract_properties(schema)
    end

    private

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

    def expected_pattern(entry)
      if entry.key?('pattern')
        entry['pattern']
      elsif entry.key?('anyOf')
        entry['anyOf'].select do |condition|
          condition.key?('pattern')
        end.pluck('pattern').join('|')
      end
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
