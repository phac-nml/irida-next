# frozen_string_literal: true

module Projects
  # Workflow executions controller for projects
  class WorkflowExecutionsController < ApplicationController
    include BreadcrumbNavigation
    include Metadata
    include WorkflowExecutionActions

    before_action :namespace

    private

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by!(id: params[:id], submitter: @project.namespace.automation_bot)
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :automated, scope_options: { project: @project })
    end

    def current_page
      @current_page = 'workflow executions'
    end

    def context_crumbs
      @context_crumbs =
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
  end
end
