# frozen_string_literal: true

module DataExports
  # Service used to Create Data Export
  class CreateService < BaseService
    DataExportCreateError = Class.new(StandardError)
    def initialize(user = nil, params = {})
      super
    end

    def execute
      @data_export = DataExport.new(params)

      validate_params

      @data_export.export_type == 'analysis' ? validate_analysis_id : validate_sample_ids

      assign_initial_export_attributes

      DataExports::CreateJob.perform_later(@data_export) if @data_export.valid?
      @data_export
    rescue DataExports::CreateService::DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    def validate_params
      # export_type and export_parameters[ids] are required for data_exports
      unless params.key?('export_type') && params.key?('export_parameters') && params['export_parameters'].key?('ids')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_required_parameters')
      end

      validate_linelist_params if params['export_type'] == 'linelist'
    end

    # linelist exports requires export_parameters[metadata_fields] and export_parameters[namespace]
    def validate_linelist_params
      unless params['export_parameters'].key?('metadata_fields')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_metadata_fields')
      end

      validate_linelist_format

      validate_linelist_namespace_type
    end

    def validate_linelist_format
      unless params['export_parameters'].key?('format')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_file_format')
      end

      return if %w[xlsx csv].include?(params['export_parameters']['format'])

      raise DataExportCreateError, I18n.t('services.data_exports.create.invalid_file_format')
    end

    def validate_linelist_namespace_type
      unless params['export_parameters'].key?('namespace_type')
        raise DataExportCreateError, I18n.t('services.data_exports.create.missing_namespace_type')
      end

      return if %w[Group Project].include?(params['export_parameters']['namespace_type'])

      raise DataExportCreateError, I18n.t('services.data_exports.create.invalid_namespace_type')
    end

    # Find the project_ids for each sample, and search/validate the unique set of ids to ensure user has authorization
    # to export the chosen samples' data
    def validate_sample_ids
      samples = Sample.where(id: params['export_parameters']['ids'])

      unless samples.count == params['export_parameters']['ids'].count
        raise DataExportCreateError, I18n.t('services.data_exports.create.invalid_sample_id')
      end

      projects = Project.where(id: samples.select(:project_id))
      projects.each do |project|
        authorize! project, to: :export_sample_data?
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

    def assign_initial_export_attributes
      @data_export.user = current_user
      @data_export.status = 'processing'
      @data_export.name = nil if params.key?('name') && params['name'].empty?

      @data_export.save
    end
  end
end
