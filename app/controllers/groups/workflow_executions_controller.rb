# frozen_string_literal: true

module Groups
  # Workflow executions controller for groups
  class WorkflowExecutionsController < Groups::ApplicationController
    include BreadcrumbNavigation
    include Metadata
    include WorkflowExecutionActions

    before_action :namespace

    private

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end

    def namespace
      @namespace = group
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by(id: params[:id], namespace:, shared_with_namespace: true)

      raise ActiveRecord::RecordNotFound if @workflow_execution.nil?
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :group_shared,
                                          scope_options: { group: @group })
    end

    def current_page
      @current_page = t(:'general.default_sidebar.workflows')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: I18n.t('groups.workflow_executions.index.title'),
          path: group_workflow_executions_path
        }]
      return unless action_name == 'show' && !@workflow_execution.nil?

      @context_crumbs +=
        [{
          name: @workflow_execution.id,
          path: group_workflow_execution_path(@workflow_execution)
        }]
    end

    protected

    def layout_fixed
      @fixed = false
    end

    def redirect_path
      group_workflow_executions_path
    end
  end
end
