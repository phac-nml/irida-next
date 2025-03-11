# frozen_string_literal: true

# Common workflow execution actions
module WorkflowExecutionActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include ListActions

  included do
    before_action :set_default_tab, only: :show
    before_action :current_page, only: %i[show index]
    before_action :workflow_execution, only: %i[show cancel destroy update edit]
    before_action proc { view_authorizations }, only: %i[index]
    before_action proc { show_view_authorizations }, only: %i[show]
  end

  TABS = %w[summary params samplesheet files].freeze

  def index
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @q = load_workflows.ransack(params[:q])
    @search_params = search_params

    set_default_sort
    @pagy, @workflow_executions = pagy_with_metadata_sort(@q.result)
  end

  def edit
    authorize! @workflow_execution

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def update # rubocop:disable Metrics/MethodLength
    respond_to do |format|
      format.turbo_stream do
        @updated = WorkflowExecutions::UpdateService.new(@workflow_execution, current_user,
                                                         workflow_execution_update_params).execute
        if @updated
          render status: :ok,
                 locals: { type: 'success',
                           message: t('concerns.workflow_execution_actions.update.success',
                                      workflow_name: @workflow_execution.metadata['workflow_name']) }

        else
          render status: :unprocessable_entity, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.update.error',
                                      workflow_name: @workflow_execution.metadata['workflow_name'])
          }
        end
      end
    end
  end

  def show
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    case @tab
    when 'files'
      @samples_workflow_executions = @workflow_execution.samples_workflow_executions
      @attachments = Attachment.where(attachable: @workflow_execution)
                               .or(Attachment.where(attachable: @samples_workflow_executions))
    when 'params'
      @workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                             @workflow_execution.metadata['workflow_version'],
                                                             'available')
    when 'samplesheet'
      format_samplesheet_params
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength
    WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

    respond_to do |format|
      format.turbo_stream do
        if @workflow_execution.deleted?
          flash[:success] =
            t('concerns.workflow_execution_actions.destroy.success',
              workflow_name: @workflow_execution.metadata['workflow_name'])
          redirect_to redirect_path
        else
          render status: :unprocessable_entity, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.destroy.error',
                                      workflow_name: @workflow_execution.metadata['workflow_name'])
          }
        end
      end
    end
  end

  def cancel # rubocop:disable Metrics/MethodLength
    WorkflowExecutions::CancelService.new(@workflow_execution, current_user).execute

    respond_to do |format|
      format.turbo_stream do
        if @workflow_execution.canceled? || @workflow_execution.canceling?
          render status: :ok,
                 locals: { type: 'success',
                           message: t('concerns.workflow_execution_actions.cancel.success',
                                      workflow_name: @workflow_execution.metadata['workflow_name']) }
        else
          render status: :unprocessable_entity, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.cancel.error',
                                      workflow_name: @workflow_execution.metadata['workflow_name'])
          }
        end
      end
    end
  end

  def select
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?
    @workflow_executions = []

    respond_to do |format|
      format.turbo_stream do
        if params[:select].present?
          @q = load_workflows.ransack(params[:q])
          @workflow_executions = @q.result.select(:id)
        end
      end
    end
  end

  def destroy_confirmation
    # if params[:single_workflow]
    #   render turbo_stream: turbo_stream.update('workflow_execution_dialog',
    #                                            partial: 'new_single_analysis_export_dialog',
    #                                            locals: new_locals), status: :ok
    # else
      render turbo_stream: turbo_stream.update('workflow_execution_dialog',
                                               partial: "shared/workflow_executions/destroy_confirmation_dialog"),
                                               status: :ok,
                                               locals: {
                                                open: true
                                               }
    # end
  end

  private

  def workflow_properties
    workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                          @workflow_execution.metadata['workflow_version'],
                                                          'available')
    return {} if workflow.blank?

    workflow.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']
  end

  def set_default_tab
    @tab = 'summary'

    return if params[:tab].nil?

    redirect_to @workflow_execution, tab: 'summary' unless TABS.include? params[:tab]

    @tab = params[:tab]
  end

  def set_default_sort
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

  protected

  def redirect_path
    raise NotImplementedError
  end

  def format_samplesheet_params
    workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                          @workflow_execution.metadata['workflow_version'],
                                                          'available')
    @samplesheet_headers = workflow.samplesheet_headers
    @samplesheet_rows = []
    @workflow_execution.samples_workflow_executions.each do |swe|
      attachments = format_attachment(swe.samplesheet_params)
      samplesheet_params = swe.samplesheet_params

      attachments.each do |key, value|
        samplesheet_params[key] = value
      end

      @samplesheet_rows << @samplesheet_headers.index_with { |header| samplesheet_params[header] }
    end
  end

  def format_attachment(samplesheet)
    attachments = {}
    # loop through samplesheet_params to fetch attachments
    # probably stored as `gid://irida/Attachment/1234`
    samplesheet.each do |key, value|
      gid = GlobalID.parse(value)
      next unless gid && gid.model_class == Attachment

      attachment = GlobalID.find(gid)
      attachments[key] = { name: attachment.file.filename, puid: attachment.puid }
    end
    attachments
  end

  def search_params
    search_params = {}
    search_params[:name_or_id_cont] = params.dig(:q, :name_or_id_cont)
    search_params
  end
end
