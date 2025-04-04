# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Create a new WorkflowExecution
  class CreateService < BaseService
    attr_accessor :workflow

    def initialize(user = nil, params = {})
      super
      @workflow = Irida::Pipelines.instance.find_pipeline_by(params[:metadata][:workflow_name],
                                                             params[:metadata][:workflow_version])
    end

    def execute # rubocop:disable Metrics/AbcSize
      return false if params.empty?

      autoset_params if @workflow
      @workflow_execution = WorkflowExecution.new(params)

      authorize! @workflow_execution.namespace, to: :submit_workflow?

      @workflow_execution.submitter = current_user

      @workflow_execution.tags = { createdBy: current_user.email }

      if @workflow_execution.valid? && params.key?(:workflow_params)
        @workflow_execution.workflow_params = sanitized_workflow_params
      end

      if @workflow_execution.save
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
