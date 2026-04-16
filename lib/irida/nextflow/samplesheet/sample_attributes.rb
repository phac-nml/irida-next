# frozen_string_literal: true

module Irida
  module Nextflow
    module Samplesheet
      # Builds samplesheet submission attributes for a set of samples.
      #
      # This class transforms schema-defined sample properties into workflow execution
      # parameters and collects file metadata for client-side rendering.
      class SampleAttributes # rubocop:disable Metrics/ClassLength
        attr_reader :samples, :properties, :file_attributes

        def initialize(samples:, properties:)
          @samples = samples
          @properties = properties
          @file_attributes = {}
        end

        def samples_workflow_executions_attributes
          attachments = samples_attachments(samples)
          samples.to_h do |sample|
            [sample.id, workflow_execution_attributes(sample, attachments)]
          end
        end

        private

        def file_cells
          properties.select do |name, entry|
            entry['cell_type'] == 'file_cell' || (%w[fastq_1
                                                     fastq_2].include?(name) && entry['cell_type'] == 'fastq_cell')
          end
        end

        def file_cell_pattern(entry)
          if entry.key?('pattern')
            entry['pattern']
          elsif entry.key?('anyOf')
            entry['anyOf'].select do |condition|
              condition.key?('pattern')
            end.pluck('pattern').join('|')
          end
        end

        def samples_attachments(samples) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          attachments = {}
          file_cells.each do |property, entry| # rubocop:disable Metrics/BlockLength
            expected_pattern = file_cell_pattern(entry)
            next unless expected_pattern

            # fastq_2 files are queried in relation to fastq_1 files, so we can skip querying them here
            next if property == 'fastq_2'

            attachments[property] = Attachment.joins(:file_blob)
                                              .where(attachable_type: 'Sample', attachable_id: samples.pluck(:id))
                                              .where(ActiveStorage::Blob.arel_table[:filename].matches_regexp(expected_pattern))

            if property == 'fastq_1'
              attachments[property] = attachments[property].where(
                Attachment.metadata_arel_node('direction').eq(nil).or(
                  Attachment.metadata_arel_node('direction').not_eq('reverse')
                )
              ).select(
                'DISTINCT ON (attachable_id) attachments.*, active_storage_blobs.filename as filename'
              ).order(
                :attachable_id,
                Arel::Nodes::Case.new.when(Attachment.metadata_arel_node('associated_attachment_id').not_eq(nil)).then(0).else(1),
                created_at: :desc, id: :desc
              ).index_by(&:attachable_id)

              if file_cells.key?('fastq_2')
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
              ).order(:attachable_id, created_at: :desc, id: :desc).index_by(&:attachable_id)
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
              [name, file_samplesheet_values(attachments[name][sample.id], sample.id, name)]
            when 'fastq_cell'
              if %w[fastq_1 fastq_2].include?(name)
                [name, file_samplesheet_values(attachments[name][sample.id], sample.id, name)]
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
