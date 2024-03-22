# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a row in the sample sheet
    class RowComponent < Component
      attr_reader :sample, :files, :properties

      def initialize(sample, index, properties)
        @sample = sample
        @index = index
        @properties = properties
        @files = filter_files
        @file_index = 0 # Keeps track of which file input is currently being rendered
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

        return render_file_cell(property, entry, fields) if property.match(/fastq_\d+/)

        return render_dropdown_cell(property, entry, fields) if entry['enum'].present?

        render_input_cell(property, fields)
      end

      def render_sample_cell(sample, fields)
        render(Samplesheet::SampleCellComponent.new(sample:, fields:))
      end

      def render_file_cell(property, entry, fields)
        pattern = if entry['anyOf']
                    entry['anyOf'].pluck('pattern').join('|')
                  else
                    entry['pattern']
                  end

        files = @files[@file_index].select { |file| file.first[Regexp.new(pattern)] }
        cell = render(Samplesheet::DropdownCellComponent.new(
                        property,
                        files,
                        fields,
                        entry['required'].present?
                      ))
        @file_index = 1
        cell
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
    end
  end
end
