# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class DestroyService < BaseWorkflowExecutionService

    def execute
      @workflow_execution.nil? ? destroy_multiple : destroy_single
    end

    private

    def destroy_single
      return unless @workflow_execution.deletable?

      authorize! @workflow_execution, to: :destroy?

      @workflow_execution.destroy

      return if @namespace.nil?

      create_activities([{ workflow_id: @workflow_execution.id,
                           workflow_name: @workflow_execution.name }])
    end

    def destroy_multiple
      authorize! @namespace, to: :destroy_workflow_executions? unless @namespace.nil?

      workflow_executions_scope = query_workflow_executions
      deletable_workflow_executions = workflow_executions_scope.where(
        id: @workflow_execution_ids,
        state: %w[completed canceled error], cleaned: true
      )

      deletable_workflow_data = deletable_workflow_executions.pluck(:id, :name).map do |id, name|
        { workflow_id: id, workflow_name: name }
      end

      deletable_workflow_executions.destroy_all

      create_activities(deletable_workflow_data) if deletable_workflow_data.count.positive? && !@namespace.nil?

      deletable_workflow_data.count
    end

    def create_activities(deleted_workflow_executions_data)
      ext_details = ExtendedDetail.create!(details: {
                                             workflow_executions_deleted_count: deleted_workflow_executions_data.count,
                                             deleted_workflow_executions_data: deleted_workflow_executions_data
                                           })
      activity = @namespace.create_activity key: 'namespaces_project_namespace.workflow_executions.destroy',
                                            owner: current_user,
                                            parameters:
                                              {
                                                workflow_executions_deleted_count:
                                                  deleted_workflow_executions_data.count,
                                                action: 'workflow_execution_destroy'
                                              }
      activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                               activity_type: 'workflow_execution_destroy')
    end
  end
end
