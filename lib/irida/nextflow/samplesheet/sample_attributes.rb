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
          samples.each_slice(1000).map do |samples_batch|
            attachments = samples_attachments(samples_batch)
            samples_batch.to_h do |sample|
              [sample.id, workflow_execution_attributes(sample, attachments)]
            end
          end.reduce({}, :merge)
        end

        private

        def autopopulated_file_cells
          @autopopulated_file_cells ||= properties.select do |_name, entry|
            Properties::FILE_CELL_TYPES.include?(entry['cell_type']) &&
              entry['autopopulate'] == true &&
              entry['pattern'].present?
          end
        end

        def samples_attachments(samples) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          attachments = {}
          autopopulated_file_cells.each do |property, entry|
            # fastq_2 files are queried in relation to fastq_1 files, so we can skip querying them here
            next if property == 'fastq_2'

            attachments[property] = Attachment.matching_filename(entry['pattern'])
                                              .where(attachable_type: 'Sample', attachable_id: samples.pluck(:id))

            if property == 'fastq_1'
              attachments[property] = attachments[property].with_direction('forward', include_nils: true).select(
                'DISTINCT ON (attachable_id) attachments.*, active_storage_blobs.filename as filename'
              ).order(:attachable_id).prefer_associated_attachment.recent.index_by(&:attachable_id)

              if autopopulated_file_cells.key?('fastq_2')
                attachments['fastq_2'] = Attachment.joins(:file_blob)
                                                   .where(id: attachments[property].map do |_, att|
                                                                att.metadata['associated_attachment_id']
                                                              end)
                                                   .select(:id, :attachable_id, :metadata, ActiveStorage::Blob.arel_table[:filename].as('filename'))
                                                   .index_by(&:attachable_id)
              end
            else

              attachments[property] = attachments[property].select(
                'DISTINCT ON (attachable_id) attachments.*, active_storage_blobs.filename as filename'
              ).order(:attachable_id).recent.index_by(&:attachable_id)
            end
          end
          attachments
        end

        def workflow_execution_attributes(sample, attachments)
          {
            'sample_id' => sample.id,
            'samplesheet_params' => sample_samplesheet_params(sample, attachments)
          }
        end

        def sample_samplesheet_params(sample, attachments) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
          properties.to_h do |name, property|
            case property['cell_type']
            when 'sample_cell'
              [name, sample.puid]
            when 'sample_name_cell'
              [name, sample.name]
            when 'file_cell'
              [name, file_samplesheet_values(attachments.dig(name, sample.id), sample.id, name)]
            when 'fastq_cell'
              if %w[fastq_1 fastq_2].include?(name)
                [name, file_samplesheet_values(attachments.dig(name, sample.id), sample.id, name)]
              else
                [name, '']
              end
            when 'metadata_cell'
              [name, metadata_samplesheet_values(sample, name, property)]
            when 'dropdown_cell', 'input_cell'
              [name, '']
            end
          end
        end

        def file_samplesheet_values(file, sample_id, column_name)
          file_attributes[sample_id] ||= {}
          file_attributes[sample_id][column_name] = {
            filename: if file.nil?
                        I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
                      else
                        file[:filename]
                      end,
            attachment_id: file.nil? ? '' : file[:id]
          }

          file.nil? ? '' : file.to_global_id.to_s
        end

        def metadata_samplesheet_values(sample, name, property)
          metadata = sample.metadata.fetch(property.fetch('x-irida-next-selected', name), '')
          metadata.empty? ? '' : metadata
        end
      end
    end
  end
end
