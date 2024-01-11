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
        @ignore_empty_values = params[:ignore_empty_values] || false
      end

      def execute
        authorize! @project, to: :update_sample?

        validate_sample_id_column

        validate_file

        # TODO: call Samples::Metadata::UpdateService

        true
      rescue Samples::Metadata::FileImportService::SampleMetadataFileImportError => e
        @project.errors.add(:base, e.message)
        false
      end

      private

      def validate_sample_id_column
        return unless @sample_id_column.nil?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.empty_sample_id_column')
      end

      def validate_file # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if @file.nil?
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.empty_file')
        end

        file_extension = File.extname(@file).downcase

        # Question: Would it be so bad if we handled ODS too?
        unless %w[.csv .xls .xlsx].include?(file_extension)
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.invalid_file_extension')
        end

        spreadsheet = Roo::Spreadsheet.open(@file)
        headers = spreadsheet.row(1)

        unless headers.include?(@sample_id_column)
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.missing_sample_id_column')
        end

        unless headers.count { |header| header != @sample_id_column } > 1
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.missing_metadata_column')
        end

        first_row = spreadsheet.row(2)

        return unless first_row.compact.empty?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.missing_metadata_row')
      end
    end
  end
end
