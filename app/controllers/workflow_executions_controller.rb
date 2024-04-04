# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  include BreadcrumbNavigation
  include Metadata

  respond_to :turbo_stream

  before_action :current_page, only: :index
  before_action :workflow_execution, only: %i[show cancel destroy]
  before_action :set_default_tab, only: :show

  TABS = %w[summary files].freeze

  def index
    @q = load_workflows.ransack(params[:q])
    set_default_sort
    @pagy, @workflows = pagy_with_metadata_sort(@q.result)
  end

  def show
    @samples_worfklow_execution = @workflow_execution.samples_workflow_executions
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
    @workflow_execution = WorkflowExecutions::CancelService.new(@workflow_execution, current_user).execute

    nil unless @workflow_execution.persisted?
  end

  def destroy
    WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

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

  def workflow_execution
    @workflow_execution = WorkflowExecution.find_by(id: params[:id], submitter: current_user)
  end

  def set_default_sort
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

  def set_default_tab
    @tab = 'summary'

    return if params[:tab].nil?

    redirect_to @workflow_execution, tab: 'summary' unless TABS.include? params[:tab]

    @tab = params[:tab]
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

  def context_crumbs
    @context_crumbs =
      [{
        name: I18n.t('workflow_executions.index.title'),
        path: workflow_executions_path
      }]
    return unless action_name == 'show' && !@workflow_execution.nil?

    @context_crumbs +=
      [{
        name: @workflow_execution.id,
        path: workflow_execution_path(@workflow_execution)
      }]
  end
end
