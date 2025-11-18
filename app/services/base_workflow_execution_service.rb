# frozen_string_literal: true

# Base root class for workflow execution services
class BaseWorkflowExecutionService < BaseService
  attr_accessor :workflow_execution, :workflow_execution_ids, :namespace

  def initialize(user = nil, params = {})
    super
    @workflow_execution = params[:workflow_execution] if params[:workflow_execution]
    @workflow_execution_ids = params[:workflow_execution_ids] if params[:workflow_execution_ids]
    @namespace = params[:namespace] if params[:namespace]
  end

  private

  def query_workflow_executions
    if @namespace
      authorized_scope(WorkflowExecution, type: :relation, as: :automated,
                                          scope_options: { project: @namespace.project })
    else
      authorized_scope(WorkflowExecution, type: :relation, as: :user,
                                          scope_options: { user: current_user })
    end
  end
end
