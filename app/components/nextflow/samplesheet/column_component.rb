# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Renders a column in the sample sheet table
    class ColumnComponent < Component
      attr_reader :header, :property, :samples, :workflow_params

      # rubocop:disable Metrics/ParameterLists
      def initialize(header:, property:, samples:, metadata_fields:, required_properties:, workflow_params:)
        @header = header
        @property = property
        @samples = samples
        @metadata_fields = metadata_fields
        @required_properties = required_properties
        @workflow_params = workflow_params
      end

      # rubocop:enable Metrics/ParameterLists

      def render_cell_type(property, entry, sample, fields, index, workflow_params) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
        case entry['cell_type']
        when 'sample_cell'
          render_sample_cell(sample, fields)
        when 'sample_name_cell'
          render_sample_name_cell(sample, fields)
        when 'fastq_cell'
          render_fastq_cell(sample, property, index, workflow_params)
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

      def render_fastq_cell(sample, property, index, workflow_params)
        selected_file = sample.samplesheet_latest_fastq_file(property, workflow_params)
        render_file_cell(sample, property, index, selected_file, workflow_params)
      end

      private

      def render_other_file_cell(sample, property, entry, fields)
        files = if entry['pattern']
                  filter_files_by_pattern(sample.sorted_files[:singles] || [], entry['pattern'])
                else
                  sample.sorted_files[:singles] || []
                end
        render_file_cell(property, entry, fields,
                         files, {}, nil)
      end

      def filter_files_by_pattern(files, pattern)
        files.select { |file| file[:filename] =~ Regexp.new(pattern) }
      end

      def render_sample_cell(sample, fields)
        render(Samplesheet::SampleCellComponent.new(sample:, fields:))
      end

      def render_sample_name_cell(sample, fields)
        render(Samplesheet::SampleNameCellComponent.new(sample:, fields:))
      end

      def render_metadata_cell(sample, name, fields)
        render(Samplesheet::MetadataCellComponent.new(sample:, name:, form: fields, required: required?))
      end

      # rubocop:disable Metrics/ParameterLists

      def render_file_cell(sample, property, index, selected, workflow_params)
        # selected_item = if selected.present?
        #                   files[0]
        #                 else
        #                   entry['autopopulate'] && files.present? ? files[0] : {}
        #                 end
        render(Samplesheet::FileCellComponent.new(
                 sample,
                 property,
                 selected,
                 index,
                 @required_properties,
                 workflow_params
               ))
      end

      # rubocop:enable Metrics/ParameterLists

      def render_dropdown_cell(property, entry, fields)
        render(Samplesheet::DropdownCellComponent.new(
                 property,
                 entry['enum'],
                 nil,
                 fields,
                 required?
               ))
      end

      def render_input_cell(property, fields)
        render(Samplesheet::TextCellComponent.new(
                 property,
                 fields:,
                 required: required?
               ))
      end

      def metadata_fields_for_field(field)
        options = @metadata_fields.include?(field) ? @metadata_fields : @metadata_fields.unshift(field)
        label = t('.default', label: field)
        options.map { |f| [f.eql?(field) ? label : f, f] }
      end

      def required?
        @required_properties.include?(@header)
      end
    end
  end
end
