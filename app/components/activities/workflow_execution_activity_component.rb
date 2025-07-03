# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type WorkflowExecution
  class WorkflowExecutionActivityComponent < Activities::BaseActivityComponent # rubocop:disable Metrics/ClassLength
    def workflow_execution_exists
      return false if @activity[:workflow_execution].nil?

      if @activity[:automated] == true
        !@activity[:workflow_execution].destroyed?
      else
        !@activity[:workflow_execution].deleted?
      end
    end

    def workflow_execution_sample_exists
      return false if @activity[:sample].nil?

      !@activity[:sample].deleted?
    end

    def activity_message
      if @activity[:automated] == true
        automated_workflow_execution_activity
      elsif workflow_execution_exists && workflow_execution_sample_exists
        workflow_execution_and_sample_exists_activity
      elsif workflow_execution_exists
        workflow_execution_exists_activity
      elsif workflow_execution_sample_exists
        workflow_execution_sample_exists_activity
      else
        href = highlighted_text(@activity[:workflow_id])
        sample_href = highlighted_text(@activity[:sample_puid])

        t(@activity[:key], user: @activity[:user], href: href, sample_href: sample_href)
      end
    end

    def automated_workflow_execution_activity
      href = if workflow_execution_exists
               link_to(
                 @activity[:workflow_id],
                 namespace_project_automated_workflow_executions_path(
                   @activity[:namespace].parent,
                   @activity[:namespace].project
                 ),
                 class: active_link_classes,
                 title:
                   t('components.activity.workflow_executions.index.link_descriptive_text')
               )
             else
               highlighted_text(@activity[:workflow_id])
             end
      t(@activity[:key], user: @activity[:user], href: href)
    end

    # Both workflow execution and sample exist
    def workflow_execution_and_sample_exists_activity # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      href = link_to(
        @activity[:workflow_id],
        namespace_project_workflow_execution_path(
          @activity[:namespace].parent,
          @activity[:namespace].project,
          @activity[:workflow_id]
        ),
        class: active_link_classes,
        title:
          t(
            'components.activity.workflow_executions.show.link_descriptive_text',
            workflow_id: @activity[:workflow_id]
          )
      )

      sample_href = link_to(
        @activity[:sample_puid],
        namespace_project_sample_path(
          @activity[:namespace].parent,
          @activity[:namespace].project,
          @activity[:sample_id]
        ),
        class: active_link_classes,
        title:
          t(
            'components.activity.samples.link_descriptive_text',
            sample_puid: @activity[:sample_puid]
          )
      )

      t(@activity[:key], user: @activity[:user], href: href, sample_href: sample_href)
    end

    # Workflow execution exists but the sample no longer does
    def workflow_execution_exists_activity # rubocop:disable Metrics/MethodLength
      href = link_to(
        @activity[:workflow_id],
        namespace_project_workflow_execution_path(
          @activity[:namespace].parent,
          @activity[:namespace].project,
          @activity[:workflow_id]
        ),
        class: active_link_classes,
        title:
          t(
            'components.activity.workflow_executions.show.link_descriptive_text',
            workflow_id: @activity[:workflow_id]
          )
      )

      sample_href = highlighted_text(@activity[:sample_puid])

      t(@activity[:key], user: @activity[:user], href: href, sample_href: sample_href)
    end

    # Workflow execution no longer exists but the sample does
    def workflow_execution_sample_exists_activity # rubocop:disable Metrics/MethodLength
      href = highlighted_text(@activity[:workflow_id])
      sample_href = link_to(
        @activity[:sample_puid],
        namespace_project_sample_path(
          @activity[:namespace].parent,
          @activity[:namespace].project,
          @activity[:sample_id]
        ),
        class: active_link_classes,
        title:
          t(
            'components.activity.samples.link_descriptive_text',
            sample_puid: @activity[:sample_puid]
          )
      )

      t(@activity[:key], user: @activity[:user], href: href, sample_href: sample_href)
    end
  end
end
