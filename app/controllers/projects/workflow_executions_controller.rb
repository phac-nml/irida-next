# frozen_string_literal: true

module Projects
  # Workflow executions controller for projects
  class WorkflowExecutionsController < Projects::ApplicationController
    include BreadcrumbNavigation
    include Metadata
    include WorkflowExecutionActions
    include Storable

    before_action :namespace
    before_action :page_title

    private

    def view_authorizations
      @allowed_to = {
        export_data: allowed_to?(:export_data?, @project),
        cancel: allowed_to?(:update?, namespace),
        destroy: allowed_to?(:update?, namespace),
        update: allowed_to?(:update?, namespace)
      }

      @render_workflow_actions = @allowed_to.slice(:export_data, :cancel, :update, :destroy).value?(true)
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
          name: I18n.t('shared.workflow_executions.index.title'),
          path: namespace_project_workflow_executions_path
        }]
      return unless action_name == 'show' && !@workflow_execution.nil?

      @context_crumbs +=
        [{
          name: @workflow_execution.id,
          path: namespace_project_workflow_execution_path(@workflow_execution)
        }]
    end

    # Paths that are needed for the destroy confirmation.
    #
    # @return @index_path [String] Sets the selection storage key, so the workflow id can be removed from local storage.
    # @return @destroy_path [String] Deletes the workflow execution on a successful confirmation.
    def destroy_paths
      @index_path = namespace_project_workflow_executions_path(@project.parent, @project)
      @destroy_path = namespace_project_workflow_execution_path(@project.parent, @project, @workflow_execution)
    end

    def destroy_multiple_paths
      @list_path = list_namespace_project_workflow_executions_path(@project.parent, @project,
                                                                   list_class: 'workflow_execution')
      @destroy_path = destroy_multiple_namespace_project_workflow_executions_path(@project.parent, @project)
    end

    def cancel_multiple_paths
      @list_path = list_namespace_project_workflow_executions_path(@project.parent, @project,
                                                                   list_class: 'workflow_execution')
      @cancel_path = cancel_multiple_namespace_project_workflow_executions_path(@project.parent, @project)
    end

    protected

    def layout_fixed
      @fixed = false
    end

    def redirect_path
      namespace_project_workflow_executions_path
    end

    def page_title # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      case action_name
      when 'index'
        @title = "#{t(:'general.default_sidebar.workflows')} · #{@project.full_name}"
      when 'show'
        workflow_execution_identifier = @workflow_execution.name.presence || @workflow_execution.id
        workflow_header = "#{t(:'shared.workflow_executions.workflow_execution')} #{workflow_execution_identifier}"
        @title = case @tab
                 when 'params'
                   [workflow_header, t(:'workflow_executions.show.tabs.params'), @project.full_name].join(' · ')
                 when 'samplesheet'
                   [workflow_header, t(:'workflow_executions.show.tabs.samplesheet'), @project.full_name].join(' · ')
                 when 'files'
                   [workflow_header, t(:'workflow_executions.show.tabs.files'), @project.full_name].join(' · ')
                 else
                   [workflow_header, t(:'workflow_executions.show.tabs.summary'), @project.full_name].join(' · ')
                 end
      end
    end
  end
end
