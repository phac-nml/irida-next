# frozen_string_literal: true

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

        validate_params

        validate_file

        # TODO: call Samples::Metadata::UpdateService

        true
      rescue Samples::Metadata::FileImportService::SampleMetadataFileImportError => e
        @project.errors.add(:base, e.message)
        false
      end

      private

      def validate_params
        if @file.nil?
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.empty_file')
        end

        return unless @sample_id_column.nil?

        raise SampleMetadataFileImportError,
              I18n.t('services.samples.metadata.import_file.empty_sample_id_column')
      end

      def validate_file
        file_extension = File.extname(@file).downcase

        if file_extension == '.csv'
          puts 'CSV'
        elsif %w[.xls .xlsx].include?(file_extension)
          puts 'EXCEL'
        else
          puts 'OTHER'
          raise SampleMetadataFileImportError,
                I18n.t('services.samples.metadata.import_file.invalid_file_extension')
        end
      end
    end
  end
end
