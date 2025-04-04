# frozen_string_literal: true

module Projects
  # Workflow executions controller for projects
  class WorkflowExecutionsController < Projects::ApplicationController
    include BreadcrumbNavigation
    include Metadata
    include WorkflowExecutionActions

    before_action :namespace

    private

    def view_authorizations
      @allowed_to = {
        export_data: allowed_to?(:export_data?, @project),
        cancel: allowed_to?(:update?, namespace),
        destroy: allowed_to?(:update?, namespace),
        update: allowed_to?(:update?, namespace)
      }
    end

    def show_view_authorizations
      @allowed_to = {
        export_data: allowed_to?(:export_data?, @project),
        cancel: allowed_to?(:cancel?, @workflow_execution),
        destroy: allowed_to?(:destroy?, @workflow_execution),
        update: allowed_to?(:update?, @workflow_execution)
      }
    end

    def namespace
      @namespace = @project.namespace
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by(
        id: params[:id],
        submitter: @project.namespace.automation_bot,
        shared_with_namespace: false
      ) || WorkflowExecution.find_by(id: params[:id], namespace:, shared_with_namespace: true)

      raise ActiveRecord::RecordNotFound if @workflow_execution.nil?
    end

    def workflow_execution_update_params
      params.expect(workflow_execution: [:name])
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :automated_and_shared,
                                          scope_options: { project: @project })
    end

    def current_page
      @current_page = t(:'general.default_sidebar.workflows')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: I18n.t('projects.workflow_executions.index.title'),
          path: namespace_project_workflow_executions_path
        }]
      return unless action_name == 'show' && !@workflow_execution.nil?

      @context_crumbs +=
        [{
          name: @workflow_execution.id,
          path: namespace_project_workflow_execution_path(@workflow_execution)
        }]
    end

    def destroy_multiple_paths
      @list_path = list_namespace_project_workflow_executions_path(@project.parent, @project,
                                                                   list_class: 'workflow_execution')
      @destroy_path = destroy_multiple_namespace_project_workflow_executions_path(@project.parent, @project)
    end

    protected

    def layout_fixed
      @fixed = false
    end

    def redirect_path
      namespace_project_workflow_executions_path
    end
  end
end
