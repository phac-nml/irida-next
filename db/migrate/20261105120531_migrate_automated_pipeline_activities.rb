# frozen_string_literal: true

# Migrates automated pipeline activities under workflow executions to activities under automated pipeline.
class MigrateAutomatedPipelineActivities < ActiveRecord::Migration[8.1]
  def change
    activities = PublicActivity::Activity.where(key: ['workflow_execution.automated_workflow.create',
                                                      'workflow_execution.automated_workflow.destroy'])

    activities.each do |activity|
      activity.parameters = {
        automated_pipeline_id: activity.parameters[:workflow_id]
      }
      if activity.key == 'workflow_execution.automated_workflow.create'
        activity.key = 'namespaces_project_namespace.automated_pipeline.create'
        activity.parameters.merge!(action: 'automated_pipeline_create')
      elsif activity.key == 'workflow_execution.automated_workflow.destroy'
        activity.key = 'namespaces_project_namespace.automated_pipeline.destroy'
        activity.parameters.merge!(action: 'automated_pipeline_destroy')
      end
      activity.save!
    end
  end
end
