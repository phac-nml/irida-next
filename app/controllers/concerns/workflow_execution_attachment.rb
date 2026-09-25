# frozen_string_literal: true

# Common Workflow Execution Attachment Logic
module WorkflowExecutionAttachment
  extend ActiveSupport::Concern
  include Metadata
  include AttachmentSearchable

  def list_workflow_execution_attachments
    all_attachments = load_attachments
    @query = attachments_query(@workflow_execution)
    @has_attachments = all_attachments.any?
    @search_params = attachment_search_params

    @pagy, @attachments = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
    @results_message = attachments_results_message

    setup_ransack_for_attachments_form(all_attachments)
  end

  private

  def load_attachments
    @workflow_execution.combined_attachments
  end
end
