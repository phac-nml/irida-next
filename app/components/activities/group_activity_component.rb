# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Groups
  class GroupActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end

    def project_link
      @activity[:group] && @activity[:project]
    end

    def group_link
      (@activity[:transferred_group] && @activity[:action] == 'group_namespace_transfer') ||
        (@activity[:created_group] && @activity[:action] == 'group_subgroup_create')
    end
  end
end
