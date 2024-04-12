# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :samples, :required_properties

    def initialize(schema:, samples:)
      @samples = samples
      @required_properties = schema['items']['required']
      extract_properties(schema)
    end

    private

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @required_file_inputs = []
      @properties.each do |property, entry|
        @properties[property]['required'] = schema['items']['required'].include?(property)
        @properties[property]['cell_type'] = identify_cell_type(property, entry)
      end
    end

    def identify_cell_type(property, entry)
      return 'sample_cell' if property == 'sample'

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
  end
end
