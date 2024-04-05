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

      sanitize_workflow_params

      @workflow_execution = WorkflowExecution.new(params)
      @workflow_execution.submitter = current_user
      @workflow_execution.state = 'new'

      if @workflow_execution.save
        WorkflowExecutionPreparationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
      end

      @workflow_execution
    end

    def sanitize_workflow_params # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      workflow = Irida::Pipelines.find_pipeline_by(params['metadata']['workflow_name'],
                                                   params['metadata']['workflow_version'])
      workflow_schema = JSON.parse(workflow.schema_loc.read)

      # remove blank values
      params['workflow_params'].compact_blank!

      workflow_schema['definitions'].each do |_item, definition|
        definition['properties'].each do |name, property|
          formatted_name = format_name_as_arg(name)
          next unless params['workflow_params'].key?(formatted_name)

          case property['type']
          when 'integer'
            params['workflow_params'][formatted_name] = params['workflow_params'][formatted_name].to_i
          when 'number'
            params['workflow_params'][formatted_name] = params['workflow_params'][formatted_name].to_f
          end
        end
      end
    end
  end
end
