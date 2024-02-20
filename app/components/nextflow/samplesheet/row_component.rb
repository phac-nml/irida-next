# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a row in the sample sheet
    class RowComponent < Component
      attr_reader :sample, :files, :properties

      def initialize(sample, properties)
        @sample = sample
        @properties = properties
        @files = filter_files
        @file_index = 0 # Keeps track of which file input is currently being rendered
      end

      def filter_files # rubocop:disable Metrics/AbcSize
        first = []
        second = []

        pattern = @properties['pattern'].to_s

        @sample.attachments.each do |attachment|
          # Check that the file meets the requirements for the pipeline
          next unless pattern.nil? || attachment.file.filename.to_s.match(/#{Regexp.new(pattern)}/)

          item = [attachment.file.filename.to_s, attachment.to_global_id]
          if attachment.metadata['associated_attachment_id'].nil?
            first << item
          elsif attachment.metadata['direction'].eql?('forward')
            first.unshift(item)
          else
            second.unshift(item)
          end
        end

        [first, second]
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
        cell = render(Samplesheet::DropdownCellComponent.new(
                        property,
                        @files[@file_index],
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
