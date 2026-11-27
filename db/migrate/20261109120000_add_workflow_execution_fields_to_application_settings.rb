# frozen_string_literal: true

# Adds a jsonb column to application_settings that stores admin-defined additional
# workflow execution fields (validated against config/schemas/workflow_execution_fields.json).
class AddWorkflowExecutionFieldsToApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :application_settings, :workflow_execution_fields, :jsonb, default: {}, null: false
  end
end
