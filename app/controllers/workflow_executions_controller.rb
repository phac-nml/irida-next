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
    workflow_executions = authorized_scope(WorkflowExecution, type: :relation, as: :user_and_shared,
                                                              scope_options: { user: current_user })

    shared_workflow_executions = []
    workflow_executions.where(shared_with_namespace: true).find_each do |workflow_execution|
      shared_workflow_executions.append(workflow_execution) if authorize! workflow_execution.namespace,
                                                                          to: :view_workflow_executions?
    end

    workflow_executions.where(shared_with_namespace: false)
                       .or(workflow_executions.where(id: shared_workflow_executions.map(&:id)))
  end

  def workflow_execution_params
    params.require(:workflow_execution).permit(workflow_execution_params_attributes)
  end

  def workflow_execution_update_params
    params.require(:workflow_execution).permit(:name)
  end

  def workflow_execution_params_attributes # rubocop:disable Metrics/MethodLength
    [
      :name,
      :namespace_id,
      :update_samples,
      :email_notification,
      :shared_with_namespace,
      { metadata: {},
        workflow_params: {},
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
