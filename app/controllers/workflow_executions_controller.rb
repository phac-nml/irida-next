# frozen_string_literal: true

# Workflow executions controller
class WorkflowExecutionsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include BreadcrumbNavigation
  include Metadata
  include WorkflowExecutionActions

  before_action :page_title

  def create
    @workflow_execution = WorkflowExecutions::CreateService.new(current_user, workflow_execution_params).execute

    if @workflow_execution.persisted?
      redirect_to workflow_executions_path
    else
      render turbo_stream: turbo_stream.update('samples_dialog',
                                               partial: 'error_dialog',
                                               locals: { message: t('.error_message'),
                                                         errors: @workflow_execution.errors.full_messages, open: true,
                                                         type: :alert }), status: :unprocessable_content
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
    params.require(:workflow_execution).permit(workflow_execution_params_attributes) # rubocop:disable Rails/StrongParametersExpect
  end

  def workflow_execution_update_params
    params.expect(workflow_execution: %i[name shared_with_namespace])
  end

  def workflow_execution_params_attributes
    [
      :name,
      :namespace_id,
      :update_samples,
      :email_notification,
      :shared_with_namespace,
      { metadata: {},
        workflow_params: {},
        samples_workflow_executions_attributes: samples_workflow_execution_params_attributes }
    ].compact
  end

  def samples_workflow_execution_params_attributes
    [
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
        name: I18n.t('shared.workflow_executions.index.title'),
        path: workflow_executions_path
      }]
    return unless action_name == 'show' && !@workflow_execution.nil?

    @context_crumbs +=
      [{
        name: @workflow_execution.name.presence || @workflow_execution.id,
        path: workflow_execution_path(@workflow_execution)
      }]
  end

  def redirect_path
    workflow_executions_path
  end

  def view_authorizations
    @allowed_to = {
      export_data: true,
      cancel: true,
      destroy: true,
      update: true
    }
  end

  def show_view_authorizations
    view_authorizations
  end

  # Paths that are needed for the destroy confirmation.
  #
  # @return @index_path [String] Sets the selection storage key, so the workflow id can be removed from local storage.
  # @return @destroy_path [String] Deletes the workflow execution on a successful confirmation.
  def destroy_paths
    @index_path = workflow_executions_path
    @destroy_path = workflow_execution_path(@workflow_execution)
  end

  def destroy_multiple_paths
    @list_path = list_workflow_executions_path(list_class: 'workflow_execution')
    @destroy_path = destroy_multiple_workflow_executions_path
  end

  def cancel_multiple_paths
    @list_path = list_workflow_executions_path(list_class: 'workflow_execution')
    @cancel_path = cancel_multiple_workflow_executions_path
  end

  def page_title # rubocop:disable Metrics/MethodLength
    case action_name
    when 'index'
      @title = t(:'general.default_sidebar.workflows').to_s
    when 'show'
      workflow_execution_identifier = @workflow_execution.name.presence || @workflow_execution.id
      workflow_header = "#{t(:'shared.workflow_executions.workflow_execution')} #{workflow_execution_identifier}"
      @title = case @tab
               when 'params'
                 [workflow_header, t(:'workflow_executions.show.tabs.params')].join(' · ')
               when 'samplesheet'
                 [workflow_header, t(:'workflow_executions.show.tabs.samplesheet')].join(' · ')
               when 'files'
                 [workflow_header, t(:'workflow_executions.show.tabs.files')].join(' · ')
               else
                 [workflow_header, t(:'workflow_executions.show.tabs.summary')].join(' · ')
               end
    end
  end
end
