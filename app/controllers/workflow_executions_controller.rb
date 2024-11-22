# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController
  include BreadcrumbNavigation
  include Metadata
  include WorkflowExecutionActions

  def create
    @workflow_execution = WorkflowExecutions::CreateService.new(current_user, workflow_execution_params).execute

    if @workflow_execution.persisted?
      redirect_to workflow_executions_path
    else
      render turbo_stream: [], status: :unprocessable_entity
    end
  end

  private

  def workflow_execution
    @workflow_execution = WorkflowExecution.find_by!(id: params[:id], submitter: current_user)
  end

  def load_workflows
    authorized_scope(WorkflowExecution, type: :relation, as: :user, scope_options: { user: current_user })
  end

  def workflow_execution_params
    params.require(:workflow_execution).permit(workflow_execution_params_attributes)
  end

  def workflow_execution_update_params
    params.require(:workflow_execution).permit(:name)
  end

  def workflow_execution_params_attributes
    [
      :name,
      :namespace_id,
      :workflow_type,
      :workflow_type_version,
      :workflow_engine,
      :workflow_engine_version,
      :workflow_url,
      :update_samples,
      :email_notification,
      { metadata: {},
        workflow_params: {},
        workflow_engine_parameters: {},
        samples_workflow_executions_attributes: samples_workflow_execution_params_attributes }
    ]
  end

  def samples_workflow_execution_params_attributes
    [
      :id, # index, increment for each one, not necissary for functionality
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

  def redirect_path
    workflow_executions_path
  end
end
