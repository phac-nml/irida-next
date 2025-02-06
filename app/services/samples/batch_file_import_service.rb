# frozen_string_literal: true

require 'roo'

module Samples
  # Service used to batch create samples via a file
  class BatchFileImportService < BaseSpreadsheetImportService
    def initialize(namespace, user = nil, blob_id = nil, params = {})
      @sample_name_column = params[:sample_name_column]
      @project_puid_column = params[:project_puid_column]
      @sample_description_column = params[:sample_description_column]
      required_headers = [@sample_name_column, @project_puid_column]
      super(namespace, user, blob_id, required_headers, 0, params)
    end

    def execute
      authorize! @namespace, to: :update_sample_metadata?
      validate_file
      perform_file_import
    rescue FileImportError => e
      @namespace.errors.add(:base, e.message)
      {}
    end

    protected

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
            message: I18n.t('services.spreadsheet_import.missing_field', index: index)
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

    private

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
