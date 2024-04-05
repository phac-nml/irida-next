# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Create a new WorkflowExecution
  class CreateService < BaseService
    include NextflowHelper

    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      return false if params.empty?

      @workflow_execution = WorkflowExecution.new(params)
      @workflow_execution.submitter = current_user
      @workflow_execution.state = 'new'

      @workflow_execution.workflow_params = sanitized_workflow_params if @workflow_execution.valid?

      if @workflow_execution.save
        WorkflowExecutionPreparationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
      end

      @workflow_execution
    end

    def sanitized_workflow_params # rubocop:disable Metrics/AbcSize
      workflow = Irida::Pipelines.find_pipeline_by(params[:metadata][:workflow_name],
                                                   params[:metadata][:workflow_version])
      workflow_schema = JSON.parse(workflow.schema_loc.read)

      # remove blank values
      sanitized_params = params[:workflow_params].compact_blank

      workflow_schema['definitions'].each do |_item, definition|
        definition['properties'].each do |name, property|
          formatted_name = format_name_as_arg(name)
          if sanitized_params.key?(formatted_name.to_sym)
            sanitized_params[formatted_name.to_sym] = sanitize_workflow_param(property,
                                                                              sanitized_params[formatted_name.to_sym])
          end
        end
      end

      sanitized_params
    end

    def sanitize_workflow_param(property, value)
      case property['type']
      when 'integer'
        value.to_i
      when 'number'
        value.to_f
      else
        value
      end
    end
  end
end
