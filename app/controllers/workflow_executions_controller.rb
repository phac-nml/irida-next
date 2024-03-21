# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  include Metadata
  before_action :current_page

  def index
    @q = load_workflows.ransack(params[:q])
    set_default_sort

    respond_to do |format|
      format.html do
        @has_workflows = @q.result.count.positive?
      end
      format.turbo_stream do
        @pagy, @workflows = pagy_with_metadata_sort(@q.result)
      end
    end
  end

  def create
    @workflow_execution = WorkflowExecutions::CreateService.new(current_user, workflow_execution_params).execute

    if @workflow_execution.persisted?
      redirect_to workflow_executions_path(format: :html)
    else
      render turbo_stream: [], status: :unprocessable_entity
    end
  end

  def cancel
    @workflow_execution = WorkflowExecution.find(params[:workflow_execution_id])

    @workflow_execution = WorkflowExecutions::CancelService.new(@workflow_execution, current_user).execute

    nil unless @workflow_execution.persisted?
  end

  def destroy # rubocop:disable Metrics/AbcSize
    @workflow_execution = WorkflowExecution.find(params[:id])
    WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

    @q = load_workflows.ransack(params[:q])
    @pagy, @workflows = pagy_with_metadata_sort(@q.result)

    if @workflow_execution.deleted?
      render status: :ok,
             locals: { type: 'success',
                       message: t('.success', workflow_name: @workflow_execution.metadata['workflow_name']) }
    else
      render status: :unprocessable_entity, locals: {
        type: 'alert', message: t('.error', workflow_name: @workflow_execution.metadata['workflow_name'])
      }
    end
  end

  private

  def set_default_sort
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

  def load_workflows
    WorkflowExecution.where(submitter: current_user)
  end

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
