# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Accepts samples and the samplesheet properties and processes the sample properties for samplesheet/workflow
    # submission, then forwards data to javascript/nextflow/samplesheet_controller.js
    class SampleAttributesComponent < Component
      attr_reader :properties, :samples

      def initialize(samples:, properties:, allowed_to_update_samples: true)
        @samples = samples
        @properties = properties
        @allowed_to_update_samples = allowed_to_update_samples
        @file_attributes = {}
      end

      def samples_workflow_executions_attributes
        samples.each_with_index.to_h do |sample|
          [sample.id, samples_workflow_execution_attributes(sample)]
        end
      end

      private

      def samples_workflow_execution_attributes(sample)
        sample_attributes = {
          'sample_id' => sample.id,
          'samplesheet_params' => sample_samplesheet_params(sample)
        }

        return sample_attributes unless @properties.key?('fastq_1') && @properties.key?('fastq_2')

        fastq_file_attributes = sample.most_recent_fastq_files(@properties['fastq_1'].key?('pe_only'))
        sample_attributes['samplesheet_params'].merge(fastq_file_samplesheet_values(fastq_file_attributes,
                                                                                    sample.id))
        sample_attributes
      end

      def sample_samplesheet_params(sample) # rubocop:disable Metrics/MethodLength
        @properties.to_h do |name, property|
          case property['cell_type']
          when 'sample_cell'
            [name, sample.puid]
          when 'sample_name_cell'
            [name, sample.name]
          when 'file_cell'
            [name,
             file_samplesheet_values(
               sample.most_recent_other_file(property['autopopulate'], property['pattern']), sample.id, name
             )]
          when 'metadata_cell'
            [name, metadata_samplesheet_values(sample, name, property)]
          when 'dropdown_cell', 'input_cell', 'fastq_cell'
            # fastq is queried above in samples_workflow_execution_attributes and values are merged over
            # this empty value
            [name, '']
          end
        end
      end

      def file_samplesheet_values(file, sample_id, column_name)
        @file_attributes[sample_id] = {} unless @file_attributes.key?(sample_id)
        @file_attributes[sample_id][column_name] = {
          filename: if file.empty?
                      I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
                    else
                      file[:filename]
                    end,
          attachment_id: file.empty? ? '' : file[:id]
        }
        file.empty? ? '' : file[:global_id]
      end

      def fastq_file_samplesheet_values(files, sample_id)
        fastq_samplesheet_params = {}
        files.each do |name, file|
          fastq_samplesheet_params[name] = file_samplesheet_values(file, sample_id, name)
        end
        fastq_samplesheet_params
      end

      def metadata_samplesheet_values(sample, name, property)
        metadata = sample.metadata.fetch(property.fetch('x-irida-next-selected', name), '')
        metadata.empty? ? '' : metadata
      end
    end
  end
end
