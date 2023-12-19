# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  layout :resolve_layout

  before_action :current_page

  def show
    @workflow = WorkflowExecution.find(params[:id])
  end

  def index
    @workflows = WorkflowExecution.where(submitter: current_user)
  end

  def create
    @workflow_execution = WorkflowExecutions::CreateService.new(current_user, workflow_execution_params).execute

    if @workflow_execution.persisted?
      redirect_to workflow_executions_path
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

  def resolve_layout
    case action_name
    when 'create'
      'application'
    else
      'workflow_executions'
    end
  end

  def current_page
    @current_page = I18n.t(:'general.default_sidebar.workflows')
  end
end
