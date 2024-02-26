# frozen_string_literal: true

module DataExports
  # Service used to Create Attachments
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

      # Call DataExportsCreateJob once created

      true
    rescue DataExports::CreateService::DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      false
    end

    def validate_params
      unless params.key?('export_type') && params.key?('export_parameters') && params['export_parameters'].key?('ids')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_required_parameters')
      end
    end

    def validate_sample_export
      projects = []
      params['export_parameters']['ids'].each do |sample_id|
        project = Project.find(Sample.find(sample_id).project_id)
        projects << project unless projects.include?(project)
      end
      projects.each do |project|
        authorize! project, to: :export_sample_data?
      end
    end
  end
end
