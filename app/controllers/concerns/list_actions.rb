# frozen_string_literal: true

# Common sample actions
module ListActions
  extend ActiveSupport::Concern

  def list
    @page = params[:page].to_i
    if params[:type] == 'sample'
      @samples = Sample.where(id: params[:sample_ids])
    elsif params[:type] == 'workflow_execution'
      @workflow_executions = WorkflowExecution.where(id: params[:workflow_execution_ids])
    end

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end
end
