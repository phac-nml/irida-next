# frozen_string_literal: true

# Migration to remove any activities from a Group where a Workflow key exists
class RemoveGroupActivitiesWithWorkflowKeys < ActiveRecord::Migration[7.2]
  def change
    # SQL option
    # reversible do |dir|
    #   dir.up do
    #     execute <<~SQL.squish
    #       DELETE FROM activities
    #       WHERE trackable_type='Namespace' AND key IN
    #       ('workflow_execution.automated_workflow_completion.outputs_and_metadata_written',
    #       'workflow_execution.automated_workflow_completion.metadata_written',
    #       'workflow_execution.automated_workflow_completion.outputs_written')
    #     SQL
    #   end
    # end

    # Ruby option
    PublicActivity::Activity.where(
      trackable_type: 'Namespace',
      key: ['workflow_execution.automated_workflow_completion.outputs_and_metadata_written',
            'workflow_execution.automated_workflow_completion.metadata_written',
            'workflow_execution.automated_workflow_completion.outputs_written']
    ).find_each(&:destroy)
  end
end
