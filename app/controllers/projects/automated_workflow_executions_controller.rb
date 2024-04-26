# frozen_string_literal: true

module Projects
  # Controller actions for Automated Workflow Executions
  class AutomatedWorkflowExecutionsController < Projects::ApplicationController
    include BreadcrumbNavigation

    before_action :current_page
    before_action :automated_workflows, only: %i[index]
    before_action :automated_workflow, only: %i[edit update destroy show]
    before_action :available_automated_workflows, only: %i[new edit]

    def index; end

    def show; end

    def new; end

    def edit; end

    def create
      @automated_workflow_execution = AutomatedWorkflowExecutions::CreateService.new(
        current_user, automated_workflow_execution_params.merge(namespace:)
      ).execute

      respond_to do |format|
        format.turbo_stream do
          if @automated_workflow_execution.persisted?
            render status: :ok
          else
            render status: :unprocessable_entity
          end
        end
      end
    end

    def update
      updated = AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow,
                                                               current_user,
                                                               automated_workflow_execution_params).execute

      respond_to do |format|
        format.turbo_stream do
          if updated
            render status: :ok
          else
            render status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow, current_user).execute

      respond_to do |format|
        format.turbo_stream do
          if @automated_workflow.destroyed?
            render status: :ok
          else
            render status: :unprocessable_entity
          end
        end
      end
    end

    private

    def automated_workflow_execution_params
      params.require(:automated_workflow_execution).permit(
        :email_notification, :update_samples, metadata: {}, workflow_params: {}
      )
    end

    protected

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def automated_workflow
      @automated_workflow = AutomatedWorkflowExecution.find_by(id: params[:id]) || not_found
    end

    def automated_workflows
      @automated_workflows = AutomatedWorkflowExecution.find_by(namespace_id: namespace.id) || not_found
    end

    def available_automated_workflows
      @available_automated_workflows = Irida::Pipelines.automatable_pipelines
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: 'Automated workflows',
          path: namespace_project_automated_workflow_executions_path
        }]
      end
    end

    def current_page
      @current_page = 'automated workflows'
    end
  end
end
