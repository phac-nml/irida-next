# frozen_string_literal: true

module Projects
  # Workflow executions controller for projects
  class WorkflowExecutionsController < ApplicationController
    include BreadcrumbNavigation
    include Metadata

    before_action :namespace
    before_action :current_page, only: :index
    before_action :workflow_execution, only: %i[show cancel destroy]
    before_action :set_default_tab, only: :show

    def index
      authorize! @namespace, to: :view_workflow_executions?

      @q = load_workflows.ransack(params[:q])
      set_default_sort
      @pagy, @workflows = pagy_with_metadata_sort(@q.result)
    end

    def show
      authorize! @namespace, to: :view_workflow_executions?

      return unless @tab == 'files'

      @samples_worfklow_executions = @workflow_execution.samples_workflow_executions
      @attachments = Attachment.where(attachable: @workflow_execution)
                               .or(Attachment.where(attachable: @samples_worfklow_executions))
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

    def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

      if @workflow_execution.deleted? && params[:redirect]
        flash[:success] = t('.success', workflow_name: @workflow_execution.metadata['workflow_name'])
        redirect_to workflow_executions_path(format: :html)
      else
        respond_to do |format|
          format.turbo_stream do
            if @workflow_execution.deleted?
              render status: :ok,
                     locals: { type: 'success',
                               message: t('.success',
                                          workflow_name: @workflow_execution.metadata['workflow_name']) }

            else
              render status: :unprocessable_entity, locals: {
                type: 'alert', message: t('.error', workflow_name: @workflow_execution.metadata['workflow_name'])
              }
            end
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

    def set_default_tab
      @tab = 'summary'

      return if params[:tab].nil?

      redirect_to @workflow_execution, tab: 'summary' unless TABS.include? params[:tab]

      @tab = params[:tab]
    end

    def load_workflows
      authorized_scope(WorkflowExecution, type: :relation, as: :namespace, scope_options: { project: @project })
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
