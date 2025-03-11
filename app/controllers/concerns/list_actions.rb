# frozen_string_literal: true

# List actions to display samples or workflow executions
module ListActions
  extend ActiveSupport::Concern

  def list
    puts params
    puts 'hihihihiihi'
    @page = params[:page].to_i
    if params[:list_class] == 'sample'
      @samples = Sample.where(id: params[:sample_ids])
    elsif params[:list_class] == 'workflow_execution'
      if params[:list_action] == 'destroy'
        set_workflows_for_destroy
      else
      @workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  private

  def set_workflows_for_destroy
    @deletable_workflow_executions = []
    @non_deletable_workflow_executions = []
    workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
    workflow_executions.each do |workflow_execution|
      if workflow_execution.deletable?
        @deletable_workflow_executions << workflow_execution
      else
        @non_deletable_workflow_executions << workflow_execution
      end
    end
  end

end
