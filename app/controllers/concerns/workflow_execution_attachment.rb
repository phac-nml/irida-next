# frozen_string_literal: true

# Common Workflow Execution Attachment Logic
module WorkflowExecutionAttachment
  extend ActiveSupport::Concern
  include Metadata

  def list_workflow_execution_attachments
    @query = attachments_query

    all_attachments = load_attachments
    @has_attachments = all_attachments.any?

    @q = all_attachments.ransack(params[:q])
    setup_ransack_for_attachments_form

    filtered_attachments = @q.result
    filtered_attachments = filtered_attachments.merge(@query.send(:advanced_query_groups)) if @query.advanced_query?

    @pagy, @attachments = pagy_with_metadata_sort(filtered_attachments, Attachment)
    @results_message = attachments_results_message
  end

  private

  def attachments_query
    Attachment::Query.new(attachment_search_params)
  end

  def load_attachments
    samples_workflow_executions = @workflow_execution.samples_workflow_executions

    Attachment.where(attachable: @workflow_execution)
              .or(Attachment.where(attachable: samples_workflow_executions))
  end

  def setup_ransack_for_attachments_form
    # Sync search values from custom Query to Ransack for accurate form display
    @q.puid_or_file_blob_filename_cont = @query.puid_or_file_blob_filename_cont
    # Set default sort order if none provided
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end

  protected

  def attachment_search_params
    search_params = {}
    search_params[:puid_or_file_blob_filename_cont] = params.dig(:q, :puid_or_file_blob_filename_cont)
    search_params[:sort] = params.dig(:q, :s)

    groups_attributes = attachment_advanced_search_groups_attributes
    search_params[:groups_attributes] = groups_attributes if groups_attributes.present?

    search_params.compact
  end

  def attachment_advanced_search_groups_attributes
    groups_attributes = params.dig(:q, :groups_attributes)
    return if groups_attributes.blank?

    # Advanced search groups use dynamic nested keys; preserve all keys.
    groups_attributes.respond_to?(:to_unsafe_h) ? groups_attributes.to_unsafe_h : groups_attributes
  end

  def attachments_results_message
    return advanced_search_results_message if @query.advanced_query?

    return if @query.puid_or_file_blob_filename_cont.blank?

    quick_search_results_message(@query.puid_or_file_blob_filename_cont)
  end
end
