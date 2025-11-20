# frozen_string_literal: true

# Common workflow execution actions
module WorkflowExecutionActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include ListActions
  include NamespacePathHelper
  include WorkflowExecutionAttachment

  included do
    before_action :set_default_tab, only: :show
    before_action :current_page, only: %i[show index]
    before_action :workflow_execution, only: %i[show cancel destroy update edit destroy_confirmation]
    before_action proc { view_authorizations }, only: %i[index]
    before_action proc { show_view_authorizations }, only: %i[show]
    before_action proc { destroy_paths }, only: %i[destroy_confirmation]
    before_action proc { destroy_multiple_paths }, only: %i[destroy_multiple_confirmation destroy_multiple]
    before_action proc { cancel_multiple_paths }, only: %i[cancel_multiple_confirmation cancel_multiple]
  end

  TABS = %w[summary params samplesheet files].freeze

  def index
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @search_params = search_params
    base_workflows = load_workflows

    setup_workflow_query(base_workflows)
    setup_backward_compatibility(base_workflows)
    configure_enum_fields
  end

  def search
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @search_params = search_params
    base_workflows = load_workflows

    setup_workflow_query(base_workflows)
    configure_enum_fields

    respond_to do |format|
      format.turbo_stream do
        if @query.valid?
          render status: :ok
        else
          render status: :unprocessable_content
        end
      end
    end
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
        WorkflowExecutions::UpdateService.new(@workflow_execution, current_user,
                                              workflow_execution_update_params).execute
        if @workflow_execution.errors.empty?
          render status: :ok,
                 locals: { type: 'success',
                           message: t('concerns.workflow_execution_actions.update.success',
                                      workflow_name: @workflow_execution.workflow.name) }

        else
          render status: :unprocessable_content, locals: {
            type: 'alert', message: error_message(@workflow_execution)
          }
        end
      end
    end
  end

  def show
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    case @tab
    when 'files'
      list_workflow_execution_attachments
    when 'params'
      @workflow = @workflow_execution.workflow
    when 'samplesheet'
      format_samplesheet_params
    when 'summary'
      @namespace_path = namespace_path(@workflow_execution.namespace)
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength
    WorkflowExecutions::DestroyService.new(current_user,
                                           { workflow_execution: @workflow_execution, namespace: @namespace }).execute

    respond_to do |format|
      format.turbo_stream do
        if @workflow_execution.deleted?
          flash[:success] =
            t('concerns.workflow_execution_actions.destroy.success',
              workflow_name: @workflow_execution.workflow.name)
          redirect_to redirect_path
        else
          render status: :unprocessable_content, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.destroy.error',
                                      workflow_name: @workflow_execution.workflow.name)
          }
        end
      end
    end
  end

  def cancel # rubocop:disable Metrics/MethodLength
    result = WorkflowExecutions::CancelService.new(
      current_user,
      { workflow_execution: @workflow_execution, namespace: @namespace }
    ).execute

    respond_to do |format|
      format.turbo_stream do
        if result && (@workflow_execution.canceled? || @workflow_execution.canceling?)
          render status: :ok,
                 locals: { type: 'success',
                           message: t('concerns.workflow_execution_actions.cancel.success',
                                      workflow_name: @workflow_execution.workflow.name) }
        else
          render status: :unprocessable_content, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.cancel.error',
                                      workflow_name: @workflow_execution.workflow.name)
          }
        end
      end
    end
  end

  def select
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?
    @workflow_executions = []

    return if params[:select].blank?

    @q = load_workflows.ransack(params[:q])
    @workflow_executions = @q.result.select(:id)
  end

  def destroy_confirmation
    authorize! @workflow_execution, to: :destroy?
    render turbo_stream: turbo_stream.update(
      'workflow_execution_dialog',
      partial: 'shared/workflow_executions/destroy_confirmation_dialog',
      locals: {
        open: true
      }
    ), status: :ok
  end

  def destroy_multiple_confirmation
    authorize! @namespace, to: :destroy_workflow_executions? unless @namespace.nil?
    render turbo_stream: turbo_stream.update(
      'workflow_execution_dialog',
      partial: 'shared/workflow_executions/destroy_multiple_confirmation_dialog',
      locals: {
        open: true
      }
    ), status: :ok
  end

  def destroy_multiple # rubocop:disable Metrics/MethodLength
    workflows_to_delete_count = destroy_multiple_params['workflow_execution_ids'].count

    deleted_workflows_count = ::WorkflowExecutions::DestroyService.new(
      current_user,
      { workflow_execution_ids: destroy_multiple_params[:workflow_execution_ids],
        namespace: @namespace }
    ).execute
    respond_to do |format|
      format.turbo_stream do
        # No selected workflows deleted
        if deleted_workflows_count.zero?
          render status: :unprocessable_content, locals: {
            type: 'alert', message: t('concerns.workflow_execution_actions.destroy_multiple.error')
          }
        # Partial workflow deletion
        elsif deleted_workflows_count.positive? && deleted_workflows_count != workflows_to_delete_count
          multi_status_messages = set_multi_status_message_for_multiple_action(deleted_workflows_count,
                                                                               workflows_to_delete_count,
                                                                               'destroy_multiple')
          render status: :multi_status,
                 locals: { messages: multi_status_messages }
        # All workflows deleted successfully
        else
          render status: :ok,
                 locals: { type: 'success',
                           message: t('concerns.workflow_execution_actions.destroy_multiple.success') }
        end
      end
    end
  end

  def cancel_multiple_confirmation
    authorize! @namespace, to: :destroy_workflow_executions? unless @namespace.nil?
    render turbo_stream: turbo_stream.update(
      'workflow_execution_dialog',
      partial: 'shared/workflow_executions/cancel_multiple_confirmation_dialog',
      locals: {
        open: true
      }
    ), status: :ok
  end

  def cancel_multiple # rubocop:disable Metrics/MethodLength
    workflows_to_cancel_count = cancel_multiple_params['workflow_execution_ids'].count

    canceled_workflows_count = ::WorkflowExecutions::CancelService.new(
      current_user,
      { workflow_execution_ids: cancel_multiple_params[:workflow_execution_ids],
        namespace: @namespace }
    ).execute
    respond_to do |format|
      format.turbo_stream do
        # No selected workflows canceled
        if canceled_workflows_count.zero?
          @messages = [{ type: 'alert', message: t('concerns.workflow_execution_actions.cancel_multiple.error') }]
          render status: :unprocessable_content

        # Partial workflow cancellation
        elsif canceled_workflows_count.positive? && canceled_workflows_count != workflows_to_cancel_count
          @messages = set_multi_status_message_for_multiple_action(canceled_workflows_count,
                                                                   workflows_to_cancel_count,
                                                                   'cancel_multiple')
          render status: :multi_status

        # All workflows canceled successfully
        else
          @messages = [{ type: 'success', message: t('concerns.workflow_execution_actions.cancel_multiple.success') }]
          render status: :ok
        end
      end
    end
  end

  private

  def workflow_properties
    workflow = @workflow_execution.workflow
    return {} if workflow.workflow_params.empty?

    workflow.workflow_params[:input_output_options][:properties][:input][:schema]['items']['properties']
  end

  def set_default_tab
    @tab = params[:tab]

    @tab_index = case @tab
                 when 'params'
                   1
                 when 'samplesheet'
                   2
                 when 'files'
                   3
                 else
                   @tab = 'summary'
                   0
                 end
  end

  def set_default_sort
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

  def set_query_results
    if @query.valid?
      @pagy, @workflow_executions = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
    else
      # Handle validation errors - set empty results
      @pagy = Pagy.new(count: 0, page: 1)
      @workflow_executions = WorkflowExecution.none
    end
  end

  def destroy_multiple_params
    params.expect(destroy_multiple: { workflow_execution_ids: [] })
  end

  def cancel_multiple_params
    params.expect(cancel_multiple: { workflow_execution_ids: [] })
  end

  def set_multi_status_message_for_multiple_action(successful_count, expected_count, action)
    [
      {
        type: 'success',
        message: t("concerns.workflow_execution_actions.#{action}.partial_success",
                   successful: "#{successful_count}/#{expected_count}")
      },
      {
        type: 'alert',
        message: t("concerns.workflow_execution_actions.#{action}.partial_error",
                   unsuccessful: "#{expected_count - successful_count}/#{expected_count}")
      }
    ]
  end

  protected

  def redirect_path
    raise NotImplementedError
  end

  def destroy_paths
    raise NotImplementedError
  end

  def destroy_multiple_paths
    raise NotImplementedError
  end

  def cancel_multiple_paths
    raise NotImplementedError
  end

  def format_samplesheet_params
    workflow = @workflow_execution.workflow

    return unless workflow.executable?

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
    updated_params = update_store(search_key,
                                  params[:q].present? ? params[:q].to_unsafe_h : {}).with_indifferent_access
    convert_ransack_sort_param(updated_params)
    updated_params.slice!(:name_or_id_cont, :groups_attributes, :sort)

    updated_params
  end

  def search_key
    if @namespace.is_a?(Project)
      "project_workflow_executions_#{@namespace.id}"
    elsif @namespace.is_a?(Group)
      "group_workflow_executions_#{@namespace.id}"
    else
      'workflow_executions'
    end
  end

  def permit_search_params
    params[:q].permit(
      :name_or_id_cont,
      :sort,
      :s,
      groups_attributes: [
        {
          conditions_attributes: [
            :field,
            :operator,
            :value,
            { value: [] }
          ]
        }
      ]
    )
  end

  def convert_ransack_sort_param(search_params)
    # Convert Ransack's :s parameter to :sort for our Query model
    if search_params[:s].present? && search_params[:sort].blank?
      search_params[:sort] = search_params.delete(:s)
    else
      search_params.delete(:s)
    end
  end

  def setup_workflow_query(base_workflows)
    # Always use base_scope to ensure proper authorization filtering
    @query = WorkflowExecution::Query.new(
      base_scope: base_workflows,
      **@search_params
    )

    @has_workflow_executions = base_workflows.any?
    set_query_results
  end

  def setup_backward_compatibility(base_workflows)
    # For backward compatibility with SearchComponent that expects Ransack
    @q = base_workflows.ransack(params[:q])
    set_default_sort
  end

  def configure_enum_fields
    # Configure enum fields for advanced search
    @workflow_execution_enum_fields = {
      'state' => state_enum_fields,
      'metadata.workflow_name' => workflow_name_enum_fields
    }
  end

  def state_enum_fields
    {
      values: WorkflowExecution.states.keys.map(&:downcase),
      translation_key: 'workflow_executions.state',
      labels: WorkflowExecution.states.keys.index_with { |k| I18n.t("workflow_executions.state.#{k}") }
    }
  end

  def workflow_name_enum_fields
    workflows = Irida::Pipelines.instance.pipelines('executable')
    workflow_names = workflows.map { |_pipeline_id, pipeline| pipeline.name[I18n.locale.to_s] }
                                .compact_blank

    {
      values: workflow_names,
      translation_key: 'pipelines.name',
      labels: workflow_names.index_with { |name| name }
    }
  end
end
