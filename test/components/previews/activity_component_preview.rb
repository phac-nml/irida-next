# frozen_string_literal: true

class ActivityComponentPreview < ViewComponent::Preview
  # Default Activity Listing
  # ---------------------------
  #
  def default
    project_namespace = Project.first.namespace
    @activities = project_namespace.human_readable_activity(project_namespace.retrieve_project_activity).reverse

    render_with_template(locals: {
                           activities: @activities
                         })
  end
end
