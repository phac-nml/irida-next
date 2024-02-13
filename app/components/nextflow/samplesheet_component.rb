# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :samples

    def initialize(schema:, samples:)
      @samples = samples
      extract_properties(schema)
    end

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @properties.each_key do |property|
        @properties[property]['required'] = schema['items']['required'].include?(property)
      end
    end

    def filter_files(sample, properties)
      paired = sample.attachments.reject { |n| n.metadata['direction'].nil? }

      names = sample.attachments.map { |a| [a.file.filename.to_s, a.to_global_id, a.metadata['direction']] }
      pattern = properties['pattern']
      pattern = properties['anyOf'].find { |p| p['pattern'].present? }['pattern'] if pattern.nil?
      names.select { |n| n[0].match(/#{Regexp.new(pattern.to_s)}/) }
    end

    def render_cell_type(property, entry, sample, fields)
      return render_sample_cell(sample, fields) if property == 'sample'

      return render_file_cell(property, entry, sample, fields) if property.match(/fastq_\d+/)

      return render_dropdown_cell(property, entry, fields) if entry['enum'].present?

      render_input_cell(property, fields)
    end

    def render_sample_cell(sample, fields)
      render(Samplesheet::SampleCellComponent.new(sample:, fields:))
    end

    def render_file_cell(property, entry, sample, fields)
      render(Samplesheet::DropdownCellComponent.new(
               property,
               filter_files(sample, entry),
               fields:,
               prompt: t('.file_prompt')
             ))
    end

    def render_dropdown_cell(property, entry, fields)
      render(Samplesheet::DropdownCellComponent.new(
               property,
               entry['enum'],
               fields:,
               prompt: t('.dropdown_prompt')
             ))
    end

    def render_input_cell(property, fields)
      render(Samplesheet::TextCellComponent.new(
               property,
               fields:
             ))
    end
  end
end
