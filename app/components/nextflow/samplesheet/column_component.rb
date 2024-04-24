# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Renders a column in the sample sheet table
    class ColumnComponent < Component
      attr_reader :namespace_id, :header, :property, :samples

      # rubocop:disable Metrics/ParameterLists
      def initialize(namespace_id:, header:, property:, samples:, metadata_fields:, required:)
        @namespace_id = namespace_id
        @header = header
        @property = property
        @samples = samples
        @metadata_fields = metadata_fields
        @required = required
      end

      # rubocop:enable Metrics/ParameterLists

      def render_cell_type(property, entry, sample, fields, index)
        case entry['cell_type']
        when 'sample_cell'
          render_sample_cell(sample, fields)
        when 'fastq_cell'
          render_fastq_cell(sample, property, entry, fields, index)
        when 'file_cell'
          render_other_file_cell(sample, property, entry, fields)
        when 'metadata_cell'
          render_metadata_cell(sample, property, fields)
        when 'dropdown_cell'
          render_dropdown_cell(property, entry, fields)
        when 'input_cell'
          render_input_cell(property, fields)
        end
      end

      def render_fastq_cell(sample, property, entry, fields, index)
        direction = property.match(/fastq_(\d+)/)[1].to_i == 1 ? :pe_forward : :pe_reverse
        files = sample.sorted_files[direction]
        data = {
          'data-action' => 'change->nextflow--samplesheet#file_selected',
          'data-nextflow--samplesheet-target' => "select#{direction.to_s.sub!('pe_', '').capitalize}",
          'data-direction' => direction.to_s,
          'data-index' => index
        }
        render_file_cell(property, entry, fields, files,
                         @required, data)
      end

      def render_other_file_cell(sample, property, entry, fields)
        files = if entry['pattern']
                  filter_files_by_pattern(sample.sorted_files[:singles], entry['pattern'])
                else
                  sample.sorted_files[:singles]
                end
        render_file_cell(property, entry, fields,
                         files, @required, {})
      end

      def filter_files_by_pattern(files, pattern)
        files.select { |file| file.first[Regexp.new(pattern)] }
      end

      def render_sample_cell(sample, fields)
        render(Samplesheet::SampleCellComponent.new(sample:, fields:))
      end

      def render_metadata_cell(sample, name, fields)
        render(Samplesheet::MetadataCellComponent.new(sample:, name:, form: fields))
      end

      # rubocop:disable Metrics/ParameterLists
      def render_file_cell(property, entry, fields, files, is_required, data)
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 files,
                 entry['autopopulate'] ? files[0] : nil,
                 fields,
                 is_required,
                 data
               ))
      end

      # rubocop:enable Metrics/ParameterLists

      def render_dropdown_cell(property, entry, fields)
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 entry['enum'],
                 nil,
                 fields,
                 @required
               ))
      end

      def render_input_cell(property, fields)
        render(Samplesheet::TextCellComponent.new(
                 property,
                 fields:
               ))
      end

      def metadata_fields_for_field(field)
        options = @metadata_fields.include?(field) ? @metadata_fields : @metadata_fields.unshift(field)
        label = t('.default', label: field)
        options.map { |f| [f.eql?(field) ? label : f, f] }
      end
    end
  end
end
