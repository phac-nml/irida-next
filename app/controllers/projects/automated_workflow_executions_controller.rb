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

    def update
      updated = AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution,
                                                               current_user,
                                                               automated_workflow_execution_params).execute

      respond_to do |format|
        format.turbo_stream do
          if updated
            render status: :ok
          else
            render status: :unprocessable_content
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
      authorize! @namespace, to: :submit_workflow?

      @query = Sample::Query.new({ project_ids: [@project.id], request: })
      advanced_search_fields(@project.namespace)

      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    def launch # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      authorize! @namespace, to: :submit_workflow?

      @search_params = trigger_launch_params.merge({ project_ids: [@project.id] })
      @query = Sample::Query.new(@search_params.merge({ request: }))

      unless @query.valid?
        respond_to do |format|
          format.turbo_stream do
            render 'trigger', status: :unprocessable_content
          end
        end
        return
      end

      unless @query.advanced_query?
        respond_to do |format|
          format.turbo_stream do
            render status: :unprocessable_content,
                   locals: {
                     type: 'alert',
                     message: t('.error.no_search_params')
                   }
          end
        end
        return
      end

      samples = @query.results
      launch_workflow_for_samples(samples)

      respond_to do |format|
        format.turbo_stream do
          render status: :ok,
                 locals: {
                   type: 'success',
                   message: t('.success',
                              workflow_name: @automated_workflow_execution.workflow.name,
                              sample_count: samples.count)
                 }
        end
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
      params.expect(q: [:sort, :name_or_puid_cont, :groups_attributes, { groups_attributes: {} }])
    end

    def launch_workflow_for_samples(samples)
      samples.each do |sample|
        pe_attachment_pair = find_newest_pe_attachment_pair(sample)
        next if pe_attachment_pair.blank?

        AutomatedWorkflowExecutions::LaunchService.new(
          @automated_workflow_execution,
          sample,
          pe_attachment_pair,
          @project.namespace.automation_bot
        ).execute
      end
    end

    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

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
