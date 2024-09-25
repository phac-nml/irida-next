# frozen_string_literal: true

# Migration to remove any activities from a group where an automated workflow key exists
class RemoveGroupActivitiesWithWorkflowKeys < ActiveRecord::Migration[7.2]
  def change
    PublicActivity::Activity.where(
      trackable_type: 'Namespace',
      key: ['workflow_execution.automated_workflow_completion.outputs_and_metadata_written',
            'workflow_execution.automated_workflow_completion.metadata_written',
            'workflow_execution.automated_workflow_completion.outputs_written']
    ).find_each(&:destroy)
  end
end
