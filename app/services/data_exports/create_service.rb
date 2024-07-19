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
      assign_initial_export_attributes

      if @data_export.valid?
        @data_export.export_type == 'analysis' ? validate_analysis_id : validate_sample_ids
        @data_export.save
        DataExports::CreateJob.perform_later(@data_export)
      end

      @data_export
    rescue DataExports::CreateService::DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    # Find the project_ids for each sample, and search/validate the unique set of ids to ensure user has authorization
    # to export the chosen samples' data
    def validate_sample_ids
      namespace = Namespace.find(params['export_parameters']['namespace_id'])

      authorize! namespace, to: :export_sample_data?

      samples = authorized_export_samples(namespace, params['export_parameters']['ids'])

      return unless samples.count != params['export_parameters']['ids'].count

      raise DataExportCreateError,
            I18n.t('services.data_exports.create.unauthorized_samples_selected')
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
    end

    def authorized_export_samples(namespace, sample_ids)
      authorized_scope(Sample, type: :relation, as: :namespace_samples,
                               scope_options: { namespace:, sample_ids: })
    end
  end
end
