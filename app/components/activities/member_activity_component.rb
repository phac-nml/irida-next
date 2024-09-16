# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Member
  class MemberActivityComponent < Component
    def initialize(activity: nil, **system_arguments)
      @activity = activity

      @system_arguments = system_arguments
    end

    def members_page
      if @activity[:member].namespace.group_namespace?
        group_members_path(@activity[:member].namespace)
      elsif @activity[:member].namespace.project_namespace?
        namespace_project_members_path(
          @activity[:member].namespace.project.parent,
          @activity[:member].namespace.project
        )
      end
    end
  end
end
