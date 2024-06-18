# frozen_string_literal: true

# Common workflow execution actions
module WorkflowExecutionActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action :set_default_tab, only: :show
    before_action :current_page, only: :index
    before_action :workflow_execution, only: %i[show cancel destroy]
  end

  TABS = %w[summary params samplesheet files].freeze

  def index
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @q = load_workflows.ransack(params[:q])
    set_default_sort
    @pagy, @workflows = pagy_with_metadata_sort(@q.result)
  end

  def show
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    case @tab
    when 'files'
      @samples_worfklow_executions = @workflow_execution.samples_workflow_executions
      @attachments = Attachment.where(attachable: @workflow_execution)
                               .or(Attachment.where(attachable: @samples_worfklow_executions))
    when 'params'
      @workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                             @workflow_execution.metadata['workflow_version'])
    when 'samplesheet'
      format_samplesheet_params
    end
  end

  def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    WorkflowExecutions::DestroyService.new(@workflow_execution, current_user).execute

    if @workflow_execution.deleted? && params[:redirect]
      flash[:success] = t('.success', workflow_name: @workflow_execution.metadata['workflow_name'])
      redirect_to redirect_path
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

  private

  def workflow_properties
    workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                          @workflow_execution.metadata['workflow_version'])
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
    @samplesheet_headers = @workflow_execution.samples_workflow_executions.first.samplesheet_params.keys
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
end
