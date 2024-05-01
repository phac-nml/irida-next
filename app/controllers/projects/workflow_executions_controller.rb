# frozen_string_literal: true

module Projects
  # Workflow executions controller
  class WorkflowExecutionsController < ApplicationController
    include BreadcrumbNavigation
    include Metadata

    before_action :namespace
    before_action :current_page, only: :index
    before_action :workflow_execution, only: %i[cancel destroy]

    def index
      @q = load_workflows.ransack(params[:q])
      set_default_sort
      @pagy, @workflows = pagy_with_metadata_sort(@q.result)
    end

    def cancel
      WorkflowExecutions::CancelService.new(@workflow_execution, current_user).execute

      respond_to do |format|
        format.turbo_stream do
          if @workflow_execution.canceled? || @workflow_execution.canceling?
            render status: :ok,
                   locals: { type: 'success',
                             message: t('.success', workflow_name: @workflow_execution.metadata['workflow_name']) }

          else
            render status: :unprocessable_entity, locals: {
              type: 'alert', message: t('.error', workflow_name: @workflow_execution.metadata['workflow_name'])
            }
          end
        end
      end
    end

    def destroy
      WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

      respond_to do |format|
        format.turbo_stream do
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
      end
    end

    private

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.find_by!(id: params[:id], submitter: current_user)
    end

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :namespace, scope_options: { project: @project })
    end

    def current_page
      @current_page = 'Workflow Executions'
    end

    def context_crumbs
      @context_crumbs =
        [{
          name: I18n.t('workflow_executions.index.title'),
          path: workflow_executions_path
        }]
    end
  end
end
