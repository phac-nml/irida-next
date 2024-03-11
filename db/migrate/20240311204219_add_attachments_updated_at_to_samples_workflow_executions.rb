# frozen_string_literal: true

# migration to add attachments updated at column to samples workflow executions table
class AddAttachmentsUpdatedAtToSamplesWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :samples_workflow_executions, :attachments_updated_at, :datetime
  end
end
