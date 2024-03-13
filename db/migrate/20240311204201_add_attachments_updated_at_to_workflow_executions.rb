# frozen_string_literal: true

# migration to add attachments updated at column to workflow executions table
class AddAttachmentsUpdatedAtToWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :attachments_updated_at, :datetime
  end
end
