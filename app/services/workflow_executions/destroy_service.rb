# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class DestroyService < BaseService
    def initialize(user = nil, params = {})
      super
      @workflow_execution = params[:workflow_execution] if params[:workflow_execution]
      @workflow_execution_ids = params[:workflow_execution_ids] if params[:workflow_execution_ids]
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
      workflows = WorkflowExecution.where(
        id: @workflow_execution_ids, state: %w[completed canceled error], cleaned: true
      )

      workflows.each do |workflow|
        authorize! workflow, to: :destroy?
      end

      workflows_to_delete_count = workflows.count

      workflows.destroy_all

      workflows_to_delete_count
    end
  end
end
