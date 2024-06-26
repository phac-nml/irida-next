# frozen_string_literal: true

module Projects
  # Controller actions for Automated Workflow Executions
  class AutomatedWorkflowExecutionsController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include BreadcrumbNavigation

    before_action :namespace
    before_action :automated_workflow_executions, only: %i[index update]
    before_action :automated_workflow_execution, only: %i[edit update destroy show]
    before_action :available_automated_workflows, only: %i[new edit]
    before_action :current_page, only: %i[index show]

    def index
      authorize! @namespace, to: :view_automated_workflow_executions?
    end

    def show
      authorize! @namespace, to: :view_automated_workflow_executions?
    end

    def new
      authorize! @namespace, to: :create_automated_workflow_executions?

      @workflow = if params[:workflow_name].present? && params[:workflow_version].present?
                    Irida::Pipelines.instance.find_pipeline_by(params[:workflow_name], params[:workflow_version])
                  end
    end

    def edit
      authorize! @namespace, to: :update_automated_workflow_executions?
      @workflow = Irida::Pipelines.instance.find_pipeline_by(@automated_workflow_execution.metadata['workflow_name'],
                                                             @automated_workflow_execution.metadata['workflow_version'])
      render turbo_stream: turbo_stream.update('automated_workflow_execution_modal',
                                               partial: 'edit_dialog',
                                               locals: {
                                                 open: true
                                               }), status: :ok
    end

    def create # rubocop:disable Metrics/MethodLength
      @automated_workflow_execution = AutomatedWorkflowExecutions::CreateService.new(
        current_user, automated_workflow_execution_params.merge(namespace:)
      ).execute

      respond_to do |format|
        format.turbo_stream do
          if @automated_workflow_execution.persisted?
            render status: :ok,
                   locals: { type: 'success',
                             message: t('.success',
                                        workflow_name: @automated_workflow_execution.metadata['workflow_name']) }
          else
            render status: :unprocessable_entity,
                   locals: {
                     type: 'alert', message: t('.error',
                                               workflow_name: @automated_workflow_execution.metadata['workflow_name'])
                   }
          end
        end
      end
    end

    def update
      updated = AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution,
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

    def destroy # rubocop:disable Metrics/MethodLength
      AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow_execution, current_user).execute

      respond_to do |format|
        format.turbo_stream do
          if @automated_workflow_execution.destroyed?
            render status: :ok,
                   locals: { type: 'success',
                             message: t('.success',
                                        workflow_name: @automated_workflow_execution.metadata['workflow_name']) }
          else
            render status: :unprocessable_entity,
                   locals: {
                     type: 'alert', message: t('.error',
                                               workflow_name: @automated_workflow_execution.metadata['workflow_name'])
                   }
          end
        end
      end
    end

    private

    def current_page
      @current_page = t(:'projects.sidebar.automated_workflow_executions').downcase
    end

    def automated_workflow_execution_params
      params.require(:workflow_execution).permit(
        :name, :email_notification, :update_samples, metadata: {}, workflow_params: {}
      )
    end

    protected

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def automated_workflow_execution
      @automated_workflow_execution = AutomatedWorkflowExecution.find_by(id: params[:id]) || not_found
    end

    def automated_workflow_executions
      @automated_workflow_executions = AutomatedWorkflowExecution
                                       .where(namespace_id: namespace.id)
                                       .order(updated_at: :desc)
    end

    def available_automated_workflows
      @available_automated_workflows = Irida::Pipelines.instance.automatable_pipelines
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: t('projects.automated_workflow_executions.index.title'),
          path: namespace_project_automated_workflow_executions_path
        }]
      end
    end
  end
end
