# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a row in the sample sheet
    class RowComponent < Component
      attr_reader :sample, :files, :properties

      def initialize(sample, index, properties)
        @sample = sample
        @index = index
        @properties = format_properties(properties)
        @files = filter_files
      end

      def format_properties(properties)
        properties.map do |name, entry|
          if check_for_file(entry)
            properties[name]['pattern'] = entry['pattern'] || entry['anyOf'].pluck('pattern').compact!.join('|')
          end
        end
        properties
      end

      def filter_files
        first = []
        pairs = []

        @sample.attachments.each do |attachment|
          item = [attachment.file.filename.to_s, attachment.to_global_id]
          if attachment.metadata['associated_attachment_id'].nil?
            first << item
          elsif attachment.metadata['direction'].eql?('forward')
            first.unshift(item)
          else
            pairs.unshift(item)
          end
        end

        [first, pairs]
      end

      def render_cell_type(property, entry, sample, fields)
        return render_sample_cell(sample, fields) if property == 'sample'

        if property.match(/fastq_\d+/)
          # Subtracting 1 of the result to get the index of the file in the array
          index = property.match(/fastq_(\d+)/)[1].to_i - 1
          return render_file_cell(property, entry,
                                  fields, index)
        end

        if check_for_file(entry)
          return render_file_cell(property, entry, fields,
                                  0)
        end

        return render_dropdown_cell(property, entry, fields) if entry['enum'].present?

        render_input_cell(property, fields)
      end

      def render_sample_cell(sample, fields)
        render(Samplesheet::SampleCellComponent.new(sample:, fields:))
      end

      def render_file_cell(property, entry, fields, files_index)
        files = if entry['pattern']
                  @files[files_index].select { |file| file.first[Regexp.new(entry['pattern'])] }
                else
                  @files[files_index]
                end
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 files,
                 fields,
                 entry['required'].present?
               ))
      end

      def render_dropdown_cell(property, entry, fields)
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 entry['enum'],
                 fields,
                 entry['required'].present?
               ))
      end

      def render_input_cell(property, fields)
        render(Samplesheet::TextCellComponent.new(
                 property,
                 fields:
               ))
      end

      def check_for_file(entry)
        entry['format'] == 'file-path' || (entry.key?('anyOf') && entry['anyOf'].any? do |e|
          e['format'] == 'file-path'
        end)
      end
    end
  end
end
