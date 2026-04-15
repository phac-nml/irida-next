# frozen_string_literal: true

module Irida
  module Nextflow
    module Samplesheet
      # Builds samplesheet submission attributes for a set of samples.
      #
      # This class transforms schema-defined sample properties into workflow execution
      # parameters and collects file metadata for client-side rendering.
      class SampleAttributes
        attr_reader :samples, :properties, :file_attributes

        def initialize(samples:, properties:)
          @samples = samples
          @properties = properties
          @file_attributes = {}
        end

        def samples_workflow_executions_attributes
          samples.to_h do |sample|
            [sample.id, workflow_execution_attributes(sample)]
          end
        end

        private

        def workflow_execution_attributes(sample)
          {
            'sample_id' => sample.id,
            'samplesheet_params' => sample_samplesheet_params(sample)
          }
        end

        def sample_samplesheet_params(sample) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
          fastq_2_property = properties.key?('fastq_2')

          samplesheet_params = properties.to_h do |name, property|
            case property['cell_type']
            when 'sample_cell'
              [name, sample.puid]
            when 'sample_name_cell'
              [name, sample.name]
            when 'file_cell'
              [name, file_samplesheet_values(
                sample.most_recent_other_file(property['autopopulate'], property['pattern']), sample.id, name
              )]
            when 'fastq_cell'
              if fastq_2_property
                [name, '']
              else
                [name, fastq_file_samplesheet_values(sample.most_recent_single_fastq_file(name), sample.id)]
              end
            when 'metadata_cell'
              [name, metadata_samplesheet_values(sample, name, property)]
            when 'dropdown_cell', 'input_cell'
              [name, '']
            end
          end

          return samplesheet_params unless fastq_2_property

          fastq_file_values = sample.most_recent_fastq_files(properties['fastq_1'].key?('pe_only'))
          samplesheet_params.merge!(fastq_file_samplesheet_values(fastq_file_values, sample.id))
        end

        def file_samplesheet_values(file, sample_id, column_name)
          file_attributes[sample_id] ||= {}
          file_attributes[sample_id][column_name] = {
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
          files.each_with_object({}) do |(name, file), params|
            params[name] = file_samplesheet_values(file, sample_id, name)
          end
        end

        def metadata_samplesheet_values(sample, name, property)
          metadata = sample.metadata.fetch(property.fetch('x-irida-next-selected', name), '')
          metadata.empty? ? '' : metadata
        end
      end
    end
  end
end
