# frozen_string_literal: true

# Update all metadata values to be text
class UpdateMetadataValuesToText < ActiveRecord::Migration[7.2]
  def change
    # Question: Should we do the same for all metadata columns in tables
    # attachments, workflow_executions, automated_workflow_executions, samples_workflow_executions?
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE samples SET metadata = metadata::text::jsonb;
        SQL
      end
    end
  end
end
