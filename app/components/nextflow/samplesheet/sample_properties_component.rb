# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Accepts samples and the samplesheet properties and processes the sample properties for samplesheet/workflow
    # submission, then forwards data to javascript/nextflow/samplesheet_controller.js
    class SamplePropertiesComponent < Component
      attr_reader :properties, :samples

      def initialize(samples:, properties:, allowed_to_update_samples: true)
        @samples = samples
        @properties = properties
        @allowed_to_update_samples = allowed_to_update_samples
      end

      def samples_workflow_executions_attributes
        samples.each_with_index.to_h do |sample, index|
          [index, samples_workflow_execution_attributes(sample)]
        end
      end

      private

      def samples_workflow_execution_attributes(sample)
        {
          'sample_id' => sample.id,
          'samplesheet_params' => sample_samplesheet_params(sample)
        }
      end

      def sample_samplesheet_params(sample) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
        @properties.to_h do |name, property|
          case property['cell_type']
          when 'sample_cell'
            [name, { form_value: sample.puid }]
          when 'sample_name_cell'
            [name, { form_value: sample.name }]
          when 'fastq_cell'
            [name,
             file_samplesheet_values(sample.attachments.empty? ? {} : sample.most_recent_fastq_file(name,
                                                                                                    property['pattern']))]
          when 'file_cell'
            [name,
             file_samplesheet_values(sample.most_recent_other_file(property['autopopulate'], property['pattern']))]
          when 'metadata_cell'
            [name, metadata_samplesheet_values(sample, name, property)]
          when 'dropdown_cell' || 'input_cell'
            [name, { form_value: '' }]
          end
        end
      end

      def file_samplesheet_values(file)
        { form_value: file.empty? ? '' : file[:global_id],
          filename: if file.empty?
                      I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
                    else
                      file[:filename]
                    end,
          attachment_id: file.empty? ? '' : file[:id] }
      end

      def metadata_samplesheet_values(sample, name, property)
        metadata = sample.metadata.fetch(property.fetch('x-irida-next-selected', name), '')
        { form_value: metadata.empty? ? '' : metadata }
      end
    end
  end
end
