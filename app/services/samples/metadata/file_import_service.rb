# frozen_string_literal: true

require 'roo'

module Samples
  module Metadata
    # Service used to import sample metadata via a file
    class FileImportService < BaseService
      SampleMetadataFileImportError = Class.new(StandardError)

      def initialize(project, user = nil, params = {})
        super(user, params)
        @project = project
        @file = params[:file]
        @sample_id_column = params[:sample_id_column]
        @ignore_empty_values = params[:ignore_empty_values]
        @spreadsheet = nil
        @headers = nil
      end

      def execute
        authorize! @project, to: :update_sample?

        validate_sample_id_column

        validate_file

        perform_file_import
      rescue Samples::Metadata::FileImportService::SampleMetadataFileImportError => e
        @project.errors.add(:base, e.message)
        {}
      end

      private

      def validate_sample_id_column
        return unless @sample_id_column.nil?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.empty_sample_id_column')
      end

      def validate_file_extension
        file_extension = File.extname(@file).downcase

        return if %w[.csv .xls .xlsx].include?(file_extension)

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.invalid_file_extension')
      end

      def validate_file_headers
        duplicate_headers = @headers.find_all { |header| @headers.count(header) > 1 }.uniq
        unless duplicate_headers.empty?
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.duplicate_column_names')
        end

        unless @headers.include?(@sample_id_column)
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.missing_sample_id_column')
        end

        return if @headers.count { |header| header != @sample_id_column }.positive?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.missing_metadata_column')
      end

      def validate_file_rows
        first_row = @spreadsheet.row(2)
        return unless first_row.compact.empty?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.missing_metadata_row')
      end

      def validate_file
        if @file.nil?
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.empty_file')
        end

        validate_file_extension

        @spreadsheet = Roo::Spreadsheet.open(@file)
        @headers = @spreadsheet.row(1).collect(&:strip)

        validate_file_headers

        validate_file_rows
      end

      def perform_file_import
        response = {}
        parse_settings = @headers.zip(@headers).to_h

        @spreadsheet.each_with_index(parse_settings) do |metadata, index|
          next unless index.positive?

          sample_id = metadata[@sample_id_column]

          metadata.delete(@sample_id_column)
          metadata.compact! if @ignore_empty_values

          metadata_changes = process_sample_metadata_row(sample_id, metadata)
          response[sample_id] = metadata_changes if metadata_changes
        rescue ActiveRecord::RecordNotFound
          @project.errors.add(:sample,
                              I18n.t('services.samples.metadata.import_file.sample_not_found',
                                     sample_name: sample_id))
        end
        response
      end

      def process_sample_metadata_row(sample_id, metadata)
        sample = if Irida::PersistentUniqueId.valid_puid?(sample_id, Sample)
                   Sample.find_by!(puid: sample_id, project_id: @project.id)
                 else
                   Sample.find_by!(name: sample_id, project_id: @project.id)
                 end

        metadata_changes = UpdateService.new(@project, sample, current_user, { 'metadata' => metadata }).execute
        not_updated_metadata_changes = metadata_changes[:not_updated]
        return metadata_changes if not_updated_metadata_changes.empty?

        @project.errors.add(:sample,
                            I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                                   sample_name: sample_id,
                                   metadata_fields: not_updated_metadata_changes.join(', ')))
        nil
      end
    end
  end
end
