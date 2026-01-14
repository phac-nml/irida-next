# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Create a new WorkflowExecution
  class CreateService < BaseService
    attr_accessor :workflow

    def initialize(user = nil, params = {})
      super
      @workflow = Irida::Pipelines.instance.find_pipeline_by(params[:metadata][:pipeline_id],
                                                             params[:metadata][:workflow_version])
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return false if params.empty?

      autoset_params if @workflow
      @workflow_execution = WorkflowExecution.new(params)

      authorize! @workflow_execution.namespace, to: :submit_workflow?

      @workflow_execution.submitter = current_user

      @workflow_execution.tags = { createdBy: current_user.email, namespaceId: @workflow_execution.namespace.puid,
                                   samplesCount: @workflow_execution.samples_workflow_executions.size.to_s }

      if @workflow_execution.valid? && params.key?(:workflow_params)
        @workflow_execution.workflow_params = sanitized_workflow_params
      end

      # Check if required number of samples (min/max) is set for pipeline and set error to
      # non persisted workflow execution object if selected samples exceeds/doesn't meet this requirement
      validate_samples_requirement_for_pipeline(@workflow_execution)

      if @workflow_execution.errors.empty? && @workflow_execution.save
        create_activities
        WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
      end

      @workflow_execution
    end

    def sanitized_workflow_params
      workflow_schema = JSON.parse(workflow.schema_loc.read)

      # remove any nil values
      sanitized_params = params[:workflow_params].compact

      workflow_schema['definitions'].each_value do |definition|
        definition['properties'].each do |name, property|
          if sanitized_params.key?(name.to_sym)
            sanitized_params[name.to_sym] = sanitize_workflow_param(property, sanitized_params[name.to_sym])
          end
        end
      end

      sanitized_params
    end

    def autoset_params
      params.merge!(@workflow.default_params)

      return if @workflow.default_workflow_params.empty?

      params['workflow_params'].reverse_merge!(@workflow.default_workflow_params)
    end

    def sanitize_workflow_param(property, value)
      case property['type']
      when 'integer'
        value.to_i
      when 'number'
        value.to_f
      when 'boolean'
        ActiveModel::Type::Boolean.new.cast(value)
      else
        value
      end
    end

    def validate_samples_requirement_for_pipeline(workflow_execution) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      min_samples = workflow_execution.workflow.minimum_samples
      max_samples = workflow_execution.workflow.maximum_samples
      selected_sample_length = if params[:samples_workflow_executions_attributes].is_a?(Array)
                                 params[:samples_workflow_executions_attributes].length
                               else
                                 params[:samples_workflow_executions_attributes].keys.length
                               end
      if selected_sample_length < min_samples
        workflow_execution.errors.add(:base,
                                      I18n.t('services.workflow_executions.create.min_samples_required',
                                             min_samples: min_samples))
      end
      return unless max_samples.positive? && (selected_sample_length > max_samples)

      workflow_execution.errors.add(:base,
                                    I18n.t('services.workflow_executions.create.max_samples_exceeded',
                                           max_samples: max_samples))
    end

    def create_activities
      return unless @workflow_execution.submitter.automation_bot?

      @workflow_execution.namespace.create_activity key: 'workflow_execution.automated_workflow.launch',
                                                    owner: current_user,
                                                    parameters:
                                                    {
                                                      workflow_id: @workflow_execution.id,
                                                      workflow_name: @workflow_execution.name,
                                                      sample_id:
                                                      @workflow_execution.samples_workflow_executions.first.sample.id,
                                                      sample_puid:
                                                      @workflow_execution.samples_workflow_executions.first.sample.puid
                                                    }
    end
  end
end
