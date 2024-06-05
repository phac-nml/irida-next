# frozen_string_literal: true

# Common workflow execution actions
module WorkflowExecutionActions
  extend ActiveSupport::Concern

  included do
    before_action :set_default_tab, only: :show
    before_action :current_page, only: :index
    before_action :workflow_execution, only: %i[show cancel destroy]
  end

  TABS = %w[summary params samples files].freeze

  def index
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @q = load_workflows.ransack(params[:q])
    set_default_sort
    @pagy, @workflows = pagy_with_metadata_sort(@q.result)
  end

  def show
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    if @tab == 'files'
      @samples_worfklow_executions = @workflow_execution.samples_workflow_executions
      @attachments = Attachment.where(attachable: @workflow_execution)
                               .or(Attachment.where(attachable: @samples_worfklow_executions))
    elsif @tab == 'params'
      @workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                             @workflow_execution.metadata['workflow_version'])
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
end
