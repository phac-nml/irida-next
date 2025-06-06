# frozen_string_literal: true

# List actions to display samples or workflow executions
module ListActions
  extend ActiveSupport::Concern

  def list
    puts hi
    @page = params[:page].to_i
    if params[:list_class] == 'sample'
      @samples = Sample.where(id: params[:sample_ids])
    elsif params[:list_class] == 'workflow_execution'
      @workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
    end

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end
end
