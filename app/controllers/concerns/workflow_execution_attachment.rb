# frozen_string_literal: true

# Common Workflow Execution Attachment Logic
module WorkflowExecutionAttachment
  extend ActiveSupport::Concern
  include Metadata

  def list_workflow_execution_attachments
    all_attachments = load_attachments
    @has_attachments = all_attachments.count.positive?
    @q = all_attachments.ransack(params[:q])
    set_attachment_default_sort
    @pagy, @attachments = pagy_with_metadata_sort(@q.result, Attachment)
  end

  private

  def load_attachments
    samples_workflow_executions = @workflow_execution.samples_workflow_executions

    Attachment.where(attachable: @workflow_execution)
              .or(Attachment.where(attachable: samples_workflow_executions))
  end

  def set_attachment_default_sort
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end
end
