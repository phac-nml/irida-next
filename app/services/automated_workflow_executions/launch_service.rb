# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Launch an AutomatedWorkflowExecution
  class LaunchService < BaseService
    LaunchError = Class.new(StandardError)
    attr_accessor :automated_workflow_execution, :sample, :pe_attachment_pair, :workflow

    def initialize(automated_workflow_execution, sample, pe_attachment_pair, user = nil, params = {})
      super(user, params)
      @automated_workflow_execution = automated_workflow_execution
      @sample = sample
      @pe_attachment_pair = pe_attachment_pair
      @workflow = Irida::Pipelines.find_pipeline_by(@automated_workflow_execution.metadata['workflow_name'],
                                                    @automated_workflow_execution.metadata['workflow_version'])
    end

    def execute
      return false if @workflow.nil?

      authorize! @automated_workflow_execution.namespace, to: :submit_workflow?

      WorkflowExecutions::CreateService.new(@current_user, workflow_execution_params).execute
    end

    private

    def workflow_execution_params # rubocop:disable Metrics/MethodLength
      {
        metadata: @automated_workflow_execution.metadata,
        workflow_params: @automated_workflow_execution.workflow_params,
        workflow_type: @workflow.type,
        workflow_type_version: @workflow.type_version,
        workflow_engine: @workflow.engine,
        workflow_engine_version: @workflow.engine_version,
        workflow_engine_parameters: { '-r': @workflow.version },
        workflow_url: @workflow.url,
        email_notification: @automated_workflow_execution.email_notification?,
        update_samples: @automated_workflow_execution.update_samples?,
        namespace_id: @automated_workflow_execution.namespace.id,
        samples_workflow_executions_attributes: [
          {
            sample_id: @sample.id,
            samplesheet_params: {
              sample: @sample.puid,
              fastq_1: @pe_attachment_pair['forward'].to_global_id, # rubocop:disable Naming/VariableNumber
              fastq_2: @pe_attachment_pair['reverse'].to_global_id # rubocop:disable Naming/VariableNumber
            }
          }
        ]
      }.with_indifferent_access
    end
  end
end
