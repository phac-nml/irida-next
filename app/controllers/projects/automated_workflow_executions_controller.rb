# frozen_string_literal: true

module Projects
  # Controller actions for Automated Workflow Executions
  class AutomatedWorkflowExecutionsController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include BreadcrumbNavigation
    include Metadata

    before_action :namespace
    before_action :automated_workflow_executions, only: %i[index update]
    before_action :automated_workflow_execution, only: %i[edit update destroy show trigger launch]
    before_action :available_automated_workflows, only: %i[new edit]
    before_action :current_page, only: %i[index show]
    before_action :page_title

    def index
      authorize! @namespace, to: :view_automated_workflow_executions?
    end

    def show
      authorize! @namespace, to: :view_automated_workflow_executions?
    end

    def new
      authorize! @namespace, to: :create_automated_workflow_executions?

      @workflow = if params.key?(:pipeline_id) && params.key?(:workflow_version)
                    Irida::Pipelines.instance.find_pipeline_by(params[:pipeline_id],
                                                               params[:workflow_version])
                  end
    end

    def edit
      authorize! @namespace, to: :update_automated_workflow_executions?
      @workflow = @automated_workflow_execution.workflow

      respond_to do |format|
        format.turbo_stream do
          if @automated_workflow_execution.disabled || @workflow.unknown?
            render status: :unprocessable_content,
                   locals: {
                     type: 'alert', message: t('.error',
                                               workflow_name: @automated_workflow_execution.id)
                   }
          else
            render status: :ok
          end
        end
      end
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
                                        workflow_name: @automated_workflow_execution.workflow.name) }
          else
            render status: :unprocessable_content,
                   locals: {
                     type: 'alert',
                     message: t('.error',
                                workflow_name: @automated_workflow_execution.workflow.name)
                   }
          end
        end
      end
    end

    def update # rubocop:disable Metrics/MethodLength
      updated = AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution,
                                                               current_user,
                                                               automated_workflow_execution_params).execute

      respond_to do |format|
        format.turbo_stream do
          if updated
            render status: :ok, locals: { type: 'success',
                                          message: t('.success',
                                                     workflow_name: @automated_workflow_execution.workflow.name) }
          else
            render status: :unprocessable_content, locals: {
              type: 'alert',
              message: t('.error',
                         workflow_name: @automated_workflow_execution.workflow.name)
            }
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
                   locals: {
                     type: 'success',
                     message: t('.success',
                                workflow_name: @automated_workflow_execution.workflow.name)
                   }
          else
            render status: :unprocessable_content,
                   locals: {
                     type: 'alert',
                     message: t('.error',
                                workflow_name: @automated_workflow_execution.workflow.name)
                   }
          end
        end
      end
    end

    def trigger
      authorize! @namespace, to: :trigger_automated_workflow_execution?
      return not_found unless Flipper.enabled?(:trigger_automated_workflow_execution)

      @trigger_form = AutomatedWorkflowExecutions::TriggerForm.new(
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request:
      )

      @query = @trigger_form.query_object
      advanced_search_fields(@project.namespace)

      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    def launch # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      authorize! @namespace, to: :trigger_automated_workflow_execution?
      return not_found unless Flipper.enabled?(:trigger_automated_workflow_execution)

      @trigger_form = AutomatedWorkflowExecutions::TriggerForm.new(
        q: trigger_launch_params,
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request:
      )

      if @trigger_form.valid?
        samples = @trigger_form.samples
        launched_samples_count = launch_workflow_for_samples(samples)

        if launched_samples_count.zero?
          @query = @trigger_form.query_object
          @trigger_form.errors.add(:q, :no_samples_with_pe_attachments)
          render 'trigger', status: :unprocessable_content, formats: :turbo_stream
        else
          flash[:success] = t('.success',
                              workflow_name: @automated_workflow_execution.workflow.name,
                              sample_count: launched_samples_count)
          redirect_to namespace_project_workflow_executions_path(@project.parent, @project)
        end
      else
        @query = @trigger_form.query_object
        advanced_search_fields(@project.namespace)
        render 'trigger', status: :unprocessable_content, formats: :turbo_stream
      end
    end

    private

    def current_page
      @current_page = t(:'projects.sidebar.automated_workflow_executions')
    end

    def automated_workflow_execution_params
      params.expect(
        workflow_execution: [:name, :email_notification, :update_samples, { metadata: {}, workflow_params: {} }]
      )
    end

    def trigger_launch_params
      params.fetch(:q, {}).permit(:groups_attributes, { groups_attributes: {} })
    end

    def launch_workflow_for_samples(samples)
      launched_samples_count = 0
      samples.each do |sample|
        pe_attachment_pair = find_newest_pe_attachment_pair(sample)
        next if pe_attachment_pair.blank?

        AutomatedWorkflowExecutions::LaunchService.new(
          @automated_workflow_execution,
          sample,
          pe_attachment_pair,
          @project.namespace.automation_bot
        ).execute
        launched_samples_count += 1
      end

      launched_samples_count
    end

    # rubocop:disable-next Metrics/MethodLength
    def find_newest_pe_attachment_pair(sample)
      fastq_attachments = sample.attachments
                                .where(Attachment.metadata_arel_node('format').eq('fastq'))

      forward_attachments = fastq_attachments.with_direction('forward', include_nils: true)
                                             .select(
                                               'DISTINCT ON (attachable_id) attachments.*, ' \
                                               'active_storage_blobs.filename as filename'
                                             )
                                             .order(:attachable_id)
                                             .prefer_associated_attachment
                                             .recent
                                             .joins(:file_blob)

      newest_forward = forward_attachments.first
      return unless newest_forward

      newest_reverse = Attachment.joins(:file_blob)
                                 .find_by(id: newest_forward.metadata['associated_attachment_id'])

      return unless newest_reverse

      {
        'forward' => newest_forward,
        'reverse' => newest_reverse
      }
    end

    protected

    def namespace
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
      @available_automated_workflows = Irida::Pipelines.instance.pipelines('automatable')
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

    def page_title
      @title = [t(:'projects.sidebar.automated_workflow_executions'), project_title].join(' · ')
    end
  end
end
