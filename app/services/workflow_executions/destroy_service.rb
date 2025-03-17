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

      create_activity([@workflow_execution.id]) unless @namespace.nil?
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
      workflows_to_delete_count = deletable_workflow_executions.count

      workflow_executions_to_delete_ids = deletable_workflow_executions.pluck(:id)

      deletable_workflow_executions.destroy_all

      create_activity(workflow_executions_to_delete_ids) if workflows_to_delete_count.positive? && !@namespace.nil?

      workflows_to_delete_count
    end

    def create_activity(deleted_ids) # rubocop:disable Metrics/MethodLength
      if deleted_ids.count == 1
        @namespace.create_activity key: 'namespaces_project_namespace.workflow_executions.destroy',
                                   owner: current_user,
                                   parameters:
                                    {
                                      workflow_execution_id: deleted_ids.first,
                                      action: 'workflow_execution_destroy'
                                    }
      else
        @namespace.create_activity key: 'namespaces_project_namespace.workflow_executions.destroy_multiple',
                                   owner: current_user,
                                   parameters:
                                   {
                                     workflow_execution_ids: deleted_ids,
                                     action: 'workflow_execution_destroy_multiple'
                                   }
      end
    end
  end
end
