# frozen_string_literal: true

require 'roo'

module Samples
  module Metadata
    # Service used to import sample metadata via a file
    class FileImportService < BaseSpreadsheetImportService
      def initialize(namespace, user = nil, blob_id = nil, params = {})
        @sample_id_column = params[:sample_id_column]
        @selected_headers = params[:metadata_columns] || []
        @delete_metadata_with_empty_values = params[:delete_metadata_with_empty_values]
        super(namespace, user, blob_id, [@sample_id_column], 1, params)
      end

      def execute(broadcast_target = nil)
        begin
          authorize! @namespace, to: :update_sample_metadata?
          validate_file
          perform_file_import(broadcast_target)
        ensure
          cleanup_files
        end
      rescue FileImportError => e
        @namespace.errors.add(:base, e.message)
        {}
      end

      protected

      def perform_file_import(broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        response = {}
        headers = if Flipper.enabled?(:metadata_import_field_selection)
                    @selected_headers << @sample_id_column
                  else
                    @headers
                  end
        parse_settings = headers.zip(headers).to_h
        # minus 1 to exclude header
        total_sample_count = @spreadsheet.count - 1
        @spreadsheet.each_with_index(parse_settings) do |metadata, index|
          next unless index.positive?

          update_progress_bar(index, total_sample_count, broadcast_target)

          sample_id = metadata[@sample_id_column]

          metadata.delete(@sample_id_column)
          metadata.compact! unless @delete_metadata_with_empty_values

          metadata_changes = process_sample_metadata_row(sample_id, metadata)
          response[sample_id] = metadata_changes if metadata_changes
        rescue ActiveRecord::RecordNotFound
          @namespace.errors.add(:sample, error_message(sample_id))
        end

        response
      end

      private

      def error_message(sample_id)
        if @namespace.type == 'Group'
          I18n.t('services.samples.metadata.import_file.sample_not_found_within_group', sample_puid: sample_id)
        else
          I18n.t('services.samples.metadata.import_file.sample_not_found_within_project', sample_puid: sample_id)
        end
      end

      def process_sample_metadata_row(sample_id, metadata)
        sample = find_sample(sample_id)
        metadata_changes = UpdateService.new(sample.project, sample, current_user, { 'metadata' => metadata }).execute
        not_updated_metadata_changes = metadata_changes[:not_updated]
        return metadata_changes if not_updated_metadata_changes.empty?

        @namespace.errors.add(:sample,
                              I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                                     sample_name: sample_id,
                                     metadata_fields: not_updated_metadata_changes.join(', ')))
        nil
      end

      def find_sample(sample_id)
        if @namespace.type == 'Group'
          authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                   scope_options: { namespace: @namespace,
                                                    minimum_access_level: Member::AccessLevel::MAINTAINER })
            .find_by!(puid: sample_id)
        else
          project = @namespace.project
          if Irida::PersistentUniqueId.valid_puid?(sample_id, Sample)
            Sample.find_by!(puid: sample_id, project_id: project.id)
          else
            Sample.find_by!(name: sample_id, project_id: project.id)
          end
        end
      end
    end
  end
end
