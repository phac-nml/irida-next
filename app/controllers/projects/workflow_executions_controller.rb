# frozen_string_literal: true

module Projects
  # Workflow executions controller for projects
  class WorkflowExecutionsController < Projects::ApplicationController
    include BreadcrumbNavigation
    include Metadata
    include WorkflowExecutionActions

    before_action :namespace

    private

    def namespace
      @namespace = @project.namespace
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by!(id: params[:id], submitter: @project.namespace.automation_bot)
    end

    def workflow_execution_update_params
      params.require(:workflow_execution).permit(:name)
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :automated, scope_options: { project: @project })
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

    protected

    def layout_fixed
      @fixed = false
    end

    def redirect_path
      namespace_project_workflow_executions_path
    end
  end
end
