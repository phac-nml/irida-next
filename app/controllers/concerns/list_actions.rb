# frozen_string_literal: true

# List actions to display samples or workflow executions
module ListActions
  extend ActiveSupport::Concern

  def list
    @page = params[:page].to_i
    if params[:list_class] == 'sample'
      @samples = Sample.where(id: params[:sample_ids])
    elsif params[:list_class] == 'workflow_execution'
      query_workflow_executions
    end

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  private

  def query_workflow_executions
    workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
    @completed_workflow_executions = workflow_executions.where(state: 'completed')
    @non_completed_workflow_executions = workflow_executions.where.not(state: 'completed')
  end
end
