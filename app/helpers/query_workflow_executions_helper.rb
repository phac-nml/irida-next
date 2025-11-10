# frozen_string_literal: true

# helper to query workflow executions for cancel and destroy services
module QueryWorkflowExecutionsHelper
  def query_workflow_executions(namespace)
    if namespace
      authorized_scope(WorkflowExecution, type: :relation, as: :automated,
                                          scope_options: { project: namespace.project })
    else
      authorized_scope(WorkflowExecution, type: :relation, as: :user,
                                          scope_options: { user: current_user })
    end
  end
end
