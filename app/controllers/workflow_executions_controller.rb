# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  def create
    @workflow_execution = WorkflowExecution.new(workflow_execution_params)
    @workflow_execution.submitter = current_user

    if @workflow_execution.save
      render turbo_stream: [], status: :ok
    else
      render turbo_stream: [], status: :unprocessable_entity
    end
  end

  private

  def workflow_execution_params
    params.require(:workflow_execution).permit(workflow_execution_params_attributes)
  end

  def workflow_execution_params_attributes
    [
      :workflow_type,
      :workflow_type_version,
      :workflow_engine,
      :workflow_engine_version,
      :workflow_url,
      { tags: [],
        metadata: {},
        workflow_params: {},
        workflow_engine_parameters: {},
        samples_workflow_executions_attributes: samples_workflow_execution_params_attributes }
    ]
  end

  def samples_workflow_execution_params_attributes
    [
      :id,
      :sample_id,
      { samplesheet_params: {} }
    ]
  end
end
