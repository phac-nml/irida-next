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

      @data_export.export_type == 'sample' ? validate_sample_ids : validate_analysis_id

      @data_export.user = current_user
      @data_export.status = 'processing'

      @data_export.save

      DataExports::CreateJob.set(wait_until: 30.seconds.from_now).perform_later(@data_export) if @data_export.valid?
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

      @data_export.name = nil if params.key?('name') && params['name'].empty?
    end

    # Find the project_ids for each sample, and search/validate the unique set of ids to ensure user has authorization
    # to export the chosen samples' data
    def validate_sample_ids
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

    def validate_analysis_id
      unless params['export_parameters']['ids'].count == 1
        raise DataExportCreateError,
              I18n.t('services.data_exports.create.invalid_workflow_execution_id_count')
      end
      workflow_execution = WorkflowExecution.find_by(id: params['export_parameters']['ids'][0])
      if workflow_execution.nil?
        raise DataExportCreateError,
              I18n.t('services.data_exports.create.invalid_workflow_execution_id')
      end
      authorize! workflow_execution, to: :export_workflow_execution_data?
    end
  end
end
