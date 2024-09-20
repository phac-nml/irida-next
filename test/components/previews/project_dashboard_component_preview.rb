# frozen_string_literal: true

class ProjectDashboardComponentPreview < ViewComponent::Preview
  # Default Project Dashboard Listing
  # ---------------------------
  #
  def default
    @project = Project.first
    project_activities = @project.namespace.retrieve_project_activity.order(created_at: :desc).limit(10)
    @activities = @project.namespace.human_readable_activity(project_activities)
    @samples = @project.samples.order(updated_at: :desc).limit(10)

    render_with_template(locals: {
                           activities: @activities,
                           samples: @samples,
                           project: @project
                         })
  end
end
