# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class SubmissionService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false unless @workflow_execution.prepared?

      run = @wes_client.run_workflow(**@workflow_execution.as_wes_params)

      @workflow_execution.run_id = run[:run_id]

      # mark workflow execution as submitted
      @workflow_execution.state = :submitted

      @workflow_execution.save

      if @workflow_execution.submitter.automation_bot?
        @workflow_execution.namespace.create_activity key: 'workflow_execution.automated_workflow.launch',
                                                      owner: current_user,
                                                      parameters:
                                                      {
                                                        workflow_id: @workflow_execution.id,
                                                        workflow_name: @workflow_execution.name
                                                      }
      end

      @workflow_execution
    end
  end
end
