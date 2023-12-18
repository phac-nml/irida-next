# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  before_action :current_page

  def index
    # @q = authorized_workflow_executions(params).ransack(params[:q])
    # set_default_sort
    # respond_to do |format|
    #   format.html do
    #     @has_workflow_executions = @q.result.count.positive?
    #   end
    #   format.turbo_stream do
    #     @pagy, @workflow_executions = pagy(@q.result)
    #   end
    # end
  end

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

  def current_page
    @current_page = I18n.t(:'general.default_sidebar.workflows')
  end
end
