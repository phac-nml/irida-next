# frozen_string_literal: true

module Irida
  module Nextflow
    module Samplesheet
      # Builds and normalizes a samplesheet schema's properties for Nextflow UI rendering.
      #
      # This class extracts property metadata, determines cell types, resolves expected
      # patterns, and marks file fields for autopopulation when required.
      class Properties
        FILE_CELL_TYPES = %w[fastq_cell file_cell].freeze

        attr_reader :properties, :required_properties

        def initialize(schema)
          @schema = schema
          @required_properties = schema['items']['required'] || []
          @properties = build_properties
        end

        private

        def build_properties
          properties = @schema['items']['properties']
          properties.each do |property, entry|
            entry['required'] = @required_properties.include?(property)
            entry['cell_type'] = identify_cell_type(property, entry)
            entry['pattern'] = expected_pattern(entry)
          end

          if @required_properties.include?('fastq_1') && @required_properties.include?('fastq_2')
            properties['fastq_1']['pe_only'] = true
          end

          identify_autopopulated_file_properties(properties)
          properties
        end

        def expected_pattern(entry)
          return entry['pattern'] if entry.key?('pattern')

          return unless entry.key?('anyOf')

          entry['anyOf'].select do |condition|
            condition.key?('pattern')
          end.pluck('pattern').join('|')
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

        def identify_autopopulated_file_properties(properties) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          file_properties = properties.select { |_property, entry| FILE_CELL_TYPES.include?(entry['cell_type']) }
          required_file_properties = file_properties.select { |_property, entry| entry['required'] }

          file_properties.each_key do |property|
            unless required_file_properties.key?(property) || (required_file_properties.empty? && property == 'fastq_1')
              next
            end

            properties[property]['autopopulate'] = true
          end

          # If fastq_1 is required and marked for autopopulation, and fastq_2 has a pattern defined,
          # mark fastq_2 for autopopulation as well
          return unless properties.dig('fastq_1', 'autopopulate') && properties.dig('fastq_2', 'pattern').present?

          properties['fastq_2']['autopopulate'] = true
        end
      end
    end
  end
end
