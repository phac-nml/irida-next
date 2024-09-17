# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Projects
  class GroupActivityComponent < Component
    def initialize(activity: nil, **system_arguments)
      @activity = activity

      @system_arguments = system_arguments
    end

    def project_link
      @activity[:group] && @activity[:project] && !@activity[:project].namespace.nil?
    end

    def group_link
      (@activity[:transferred_group] && @activity[:action] == 'group_namespace_transfer') ||
        (@activity[:created_group] && @activity[:action] == 'group_subgroup_create')
    end

    def transfer_out
      @activity[:key].include?('transfer_out')
    end
  end
end
