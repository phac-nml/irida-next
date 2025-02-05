# frozen_string_literal: true

require 'roo'

module Samples
  # Service used to batch create samples via a file
  class BatchFileImportService < BaseService # rubocop:disable Metrics/ClassLength
    SampleFileImportError = Class.new(StandardError)

    def initialize(namespace, user = nil, blob_id = nil, params = {})
      super(user, params)
      @namespace = namespace
      @file = ActiveStorage::Blob.find(blob_id)
      @sample_name_column = params[:sample_name_column]
      @project_puid_column = params[:project_puid_column]
      @sample_description_column = params[:sample_description_column]
      @spreadsheet = nil
      @headers = nil
      @temp_import_file = Tempfile.new
    end

    def execute
      authorize! @namespace, to: :update_sample_metadata?

      validate_sample_name_column

      validate_file

      perform_file_import
    rescue Samples::BatchFileImportService::SampleFileImportError => e
      @namespace.errors.add(:base, e.message)
      {}
    end

    private

    def validate_sample_name_column
      return unless @sample_name_column.nil?

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.empty_sample_id_column')
    end

    def validate_file_extension
      file_extension = File.extname(@file.filename.to_s).downcase

      return file_extension if %w[.csv .tsv .xls .xlsx].include?(file_extension)

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.invalid_file_extension')
    end

    def validate_file_headers
      duplicate_headers = @headers.find_all { |header| @headers.count(header) > 1 }.uniq
      unless duplicate_headers.empty?
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.duplicate_column_names')
      end

      unless @headers.include?(@sample_name_column)
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.missing_sample_id_column')
      end

      # TODO: check if we have a project puid header

      # return if @headers.count { |header| header != @sample_name_column }.positive?

      # raise SampleFileImportError,
      #       I18n.t('services.samples.metadata.import_file.missing_metadata_column')
    end

    def validate_file_rows
      # Should have at least 2 rows
      first_row = @spreadsheet.row(2)
      return unless first_row.compact.empty?

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.missing_metadata_row')
    end

    def validate_file
      if @file.nil?
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.empty_file')
      end

      extension = validate_file_extension
      download_batch_import_file(extension)

      @headers = @spreadsheet.row(1).compact
      validate_file_headers

      validate_file_rows
    end

    def download_batch_import_file(extension)
      begin
        @temp_import_file.binmode
        @file.download do |chunk|
          @temp_import_file.write(chunk)
        end
      ensure
        @temp_import_file.close
      end
      @spreadsheet = if extension.eql? '.tsv'
                       Roo::CSV.new(@temp_import_file, extension:, csv_options: { col_sep: "\t" })
                     else
                       Roo::Spreadsheet.open(@temp_import_file.path, extension:)
                     end
    end

    def perform_file_import # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      response = {}
      parse_settings = @headers.zip(@headers).to_h

      @spreadsheet.each_with_index(parse_settings) do |data, index|
        next unless index.positive?

        # TODO: handle metadata

        sample_name = data[@sample_name_column]
        project_puid = data[@project_puid_column]
        description = data[@sample_description_column]

        if sample_name.nil? || project_puid.nil?
          response["index #{index}"] = {
            path: ['sample'],
            message: I18n.t('services.samples.batch_import.missing_field', index: index)
          }
          next
        end

        project = Namespaces::ProjectNamespace.find_by(puid: project_puid)&.project
        unless project
          response[sample_name] = {
            path: ['project'],
            message: I18n.t('services.samples.batch_import.project_puid_not_found', project_puid: project_puid)
          }
          next
        end

        response[sample_name] = process_sample_row(sample_name, project, description)
        cleanup_files
        response
      end
      response
    end

    def cleanup_files
      # delete the blob and temporary file as we no longer require them
      @file.purge
      @temp_import_file.unlink
    end

    def process_sample_row(name, project, description)
      sample_params = { name:, description: }
      sample = Samples::CreateService.new(current_user, project, sample_params).execute

      if sample.persisted?
        sample
      else
        sample.errors.map do |error|
          {
            path: ['sample', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end
    end
  end
end
