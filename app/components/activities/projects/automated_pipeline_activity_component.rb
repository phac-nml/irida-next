# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an automated pipeline activity for projects
    class AutomatedPipelineActivityComponent < Activities::BaseActivityComponent
      def activity_message
        href = link_to(
          @activity[:automated_pipeline_id],
          helpers.namespace_project_automated_workflow_executions_path(
            @activity[:current_project].parent,
            @activity[:current_project].project
          ),
          class: active_link_classes,
          title:
            t('components.activity.automated_pipelines.index.link_descriptive_text',
              automated_pipeline_id: @activity[:automated_pipeline_id]),
          'aria-label' =>
            t('components.activity.automated_pipelines.index.link_descriptive_text',
              automated_pipeline_id: @activity[:automated_pipeline_id])
        )

        t(@activity[:key], user: @activity[:user], href: href)
      end
    end
  end
end
