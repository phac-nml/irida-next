# frozen_string_literal: true

# Common workflow execution actions
module WorkflowExecutionActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include ListActions
  include NamespacePathHelper
  include Storable
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
    before_action proc { workflow_execution_fields }, only: %i[index search]
  end

  TABS = %w[summary params samplesheet files].freeze

  def index
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @query = workflow_execution_query
    @has_workflow_executions = load_workflows.any?
    @search_params = search_params

    @pagy, @workflow_executions = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)

    setup_ransack_for_form
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

    @query = workflow_execution_query
    @workflow_executions = @query.results.select(:id)
  end

  def search
    authorize! @namespace, to: :view_workflow_executions? unless @namespace.nil?

    @query = workflow_execution_query
    @search_params = search_params

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

  def workflow_execution_query
    WorkflowExecution::Query.new(search_params.merge({ namespace_ids: }), scope: load_workflows)
  end

  def namespace_ids
    return load_workflows.distinct.pluck(:namespace_id) if @namespace.nil?

    [@namespace.id]
  end

  # Sets up Ransack compatibility for UI components that expect a Ransack object.
  #
  # This creates a dual-object pattern:
  # - @query (WorkflowExecution::Query) - Handles actual search logic and results
  # - @q (Ransack::Search) - Used by Ransack-based UI components
  #
  # Why both objects are needed:
  # - The custom Query object provides advanced search capabilities
  # - Ransack::SortComponent (used in WorkflowExecutions::TableComponent) requires a Ransack object
  # - SearchComponent expects @q for form binding and displaying current search values
  #
  # View usage:
  # - SearchComponent: Uses @q.name_or_id_cont for displaying current search term
  # - Table headers: Ransack::SortComponent uses @q for sort links and sort state
  # - Results: @query.results provides the actual paginated workflow executions
  #
  # TODO: When updating the UI, the samples feature uses a custom SortComponent instead of Ransack::SortComponent,
  # eliminating the need for this bridging pattern. Consider refactoring workflow executions
  # to use the same approach in the future.
  def setup_ransack_for_form
    # Create Ransack object from request params for UI component compatibility
    @q = load_workflows.ransack(params[:q])
    # Sync search values from custom Query to Ransack for accurate form display
    @q.name_or_id_cont = @query.name_or_id_cont
    # Set default sort order if none provided
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

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
    permitted = permit_search_params
    # If no params provided in request, retrieve stored params from session
    # Otherwise, use the submitted params (even if empty, to clear the search)
    if params[:q].blank?
      stored = get_store(search_key) || {}
      updated_params = stored.with_indifferent_access
    else
      updated_params = update_store(search_key, permitted)
    end
    # Filter to only allow expected keys for security
    updated_params.slice!('name_or_id_cont', 'name_or_id_in', 'groups_attributes', 'sort')
    updated_params['sort'] = 'updated_at desc' unless updated_params.key?('sort')
    update_store(search_key, updated_params)

    updated_params
  end

  def permit_search_params
    return {} if params[:q].blank?

    # Use to_unsafe_h to handle complex nested form submissions
    # This matches the pattern used in samples controllers (see projects/samples_controller.rb:254)
    # Security is ensured by the .slice! call in search_params which allowlists keys
    params[:q].to_unsafe_h.with_indifferent_access
  end

  def search_key
    # Use 'global' prefix for user-level searches to avoid collision with namespace IDs
    namespace_id = @namespace&.id || "global_#{current_user.id}"
    :"#{controller_name}_#{namespace_id}_search_params"
  end

  def workflow_execution_fields
    field_config = WorkflowExecution::FieldConfiguration.new
    @workflow_execution_fields = field_config.fields
    @workflow_execution_enum_fields = field_config.enum_fields
  end
end
