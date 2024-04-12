# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a row in the sample sheet
    class RowComponent < Component # rubocop:disable Metrics/ClassLength
      attr_reader :sample, :files, :properties

      def initialize(sample, index, properties, required_properties)
        @sample = sample
        @index = index
        @properties = format_properties(properties)
        @required_properties = required_properties
        @files = sort_files
      end

      def format_properties(properties)
        properties.map do |_name, entry|
          next unless entry['fastq_cell'] || entry['file_cell']

          entry['pattern'] = entry['pattern'] || entry['anyOf'].select do |e|
            e.key?('format') && e['format'] == 'file-path'
          end.pluck('pattern').join('|')
        end
        properties
      end

      def sort_files
        singles = []
        pe_forward = []
        pe_reverse = []

        @sample.attachments.each do |attachment|
          item = [attachment.file.filename.to_s, attachment.to_global_id, { 'data-puid': attachment.puid }]
          case attachment.metadata['direction']
          when nil
            singles << item
          when 'forward'
            pe_forward << item
          else
            pe_reverse << item
          end
        end

        { singles:, pe_forward:, pe_reverse: }
      end

      def render_cell_type(property, entry, sample, fields)
        case entry['cell_type']
        when 'sample_cell'
          render_sample_cell(sample, fields)
        when 'fastq_cell'
          render_fastq_cell(property, entry, fields)
        when 'file_cell'
          render_other_file_cell(property, entry, fields)
        when 'metadata_cell'
          render_metadata_cell(sample, property, entry, fields)
        when 'dropdown_cell'
          render_dropdown_cell(property, entry, fields)
        when 'input_cell'
          render_input_cell(property, fields)
        end
      end

      def render_fastq_cell(property, entry, fields)
        index = property.match(/fastq_(\d+)/)[1].to_i - 1
        files = index.zero? ? @files[:pe_forward] : @files[:pe_reverse]
        render_file_cell(property, entry, fields, files,
                         @required_properties.include?(property))
      end

      def render_other_file_cell(property, entry, fields)
        files = if entry['pattern']
                  filter_files_by_pattern(@files[:singles], entry['pattern'])
                else
                  @files[:singles]
                end
        render_file_cell(property, entry, fields,
                         files, @required_properties.include?(property))
      end

      def filter_files_by_pattern(files, pattern)
        files.select { |file| file.first[Regexp.new(pattern)] }
      end

      def render_sample_cell(sample, fields)
        render(Samplesheet::SampleCellComponent.new(sample:, fields:))
      end

      def render_metadata_cell(sample, name, entry, fields)
        render(Samplesheet::MetadataCellComponent.new(sample:, name:, entry:, form: fields))
      end

      def render_file_cell(property, entry, fields, files, is_required) # rubocop:disable Metrics/MethodLength
        data = if entry['cell_type'] == 'fastq_cell'
                 {
                   'data-action' => 'change->nextflow--samplesheet#file_selected',
                   'data-nextflow--samplesheet-target' => 'select'
                 }
               else
                 {}
               end
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 files,
                 entry['autopopulate'] ? files[0] : nil,
                 fields,
                 is_required,
                 data
               ))
      end

      def render_dropdown_cell(property, entry, fields)
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 entry['enum'],
                 nil,
                 fields,
                 @required_properties.include?(property)
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
end
