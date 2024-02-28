# frozen_string_literal: true

module DataExports
  # Service used to Create Data Export
  class CreateService < BaseService
    DataExportCreateError = Class.new(StandardError)
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      @data_export = DataExport.new(params)

      validate_params

      validate_sample_export if @data_export.export_type == 'sample'

      @data_export.user = current_user
      @data_export.status = 'processing'

      @data_export.save
      @data_export
    rescue DataExports::CreateService::DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    # export_type and export_parameters[ids] are required for data_exports
    def validate_params
      unless params.key?('export_type') && params.key?('export_parameters') && params['export_parameters'].key?('ids')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_required_parameters')
      end
    end

    # Find the project_ids for each sample, and search/validate the unique set of ids to ensure user has authorization
    # to export the chosen samples' data
    def validate_sample_export
      project_ids = []

      params['export_parameters']['ids'].each do |sample_id|
        sample = Sample.find_by(id: sample_id)
        raise DataExportCreateError, I18n.t('services.data_exports.create.invalid_sample_id') if sample.nil?

        project_id = sample.project_id
        project_ids << project_id unless project_ids.include?(project_id)
      end

      project_ids.each do |project_id|
        authorize! Project.find(project_id), to: :export_sample_data?
      end
    end
  end
end
