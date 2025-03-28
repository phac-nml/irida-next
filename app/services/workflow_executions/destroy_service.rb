# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class DestroyService < BaseService
    def initialize(user = nil, params = {})
      super
      @workflow_execution = params[:workflow_execution] if params[:workflow_execution]
      @workflow_execution_ids = params[:workflow_execution_ids] if params[:workflow_execution_ids]
      @namespace = params[:namespace] if params[:namespace]
    end

    def execute
      @workflow_execution.nil? ? destroy_multiple : destroy_single
    end

    private

    def destroy_single
      return unless @workflow_execution.deletable?

      authorize! @workflow_execution, to: :destroy?

      @workflow_execution.destroy
    end

    def destroy_multiple
      authorize! @namespace, to: :destroy_workflow_executions? unless @namespace.nil?

      workflow_executions = WorkflowExecution.where(
        id: @workflow_execution_ids, state: %w[completed canceled error], cleaned: true
      )

      workflows_to_delete_count = workflow_executions.count

      workflow_executions.destroy_all

      workflows_to_delete_count
    end
  end
end
