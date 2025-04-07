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

      create_activity([{ id: @workflow_execution.id, name: @workflow_execution.name }]) unless @namespace.nil?
    end

    def destroy_multiple
      authorize! @namespace, to: :destroy_workflow_executions? unless @namespace.nil?

      workflow_executions_scope = if @namespace
                                    authorized_scope(WorkflowExecution, type: :relation, as: :automated,
                                                                        scope_options: { project: @namespace.project })
                                  else
                                    authorized_scope(WorkflowExecution, type: :relation, as: :user,
                                                                        scope_options: { user: current_user })
                                  end
      deletable_workflow_executions = workflow_executions_scope.where(
        id: @workflow_execution_ids,
        state: %w[completed canceled error], cleaned: true
      )

      deleted_workflow_executions = deletable_workflow_executions.pluck(:id, :name).map do |id, name|
        { id: id, name: name }
      end

      deletable_workflow_executions.destroy_all

      create_activity(deleted_workflow_executions) if deleted_workflow_executions.count.positive? && !@namespace.nil?

      deleted_workflow_executions.count
    end

    def create_activity(deleted_workflow_executions)
      @namespace.create_activity key: 'namespaces_project_namespace.workflow_executions.destroy',
                                 owner: current_user,
                                 parameters:
                                 {
                                   workflow_executions: deleted_workflow_executions,
                                   action: 'workflow_execution_destroy'
                                 }
    end
  end
end
