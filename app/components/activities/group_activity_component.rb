# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Groups
  class GroupActivityComponent < BaseActivityComponent
    def project_link
      @activity[:group] && @activity[:project]
    end

    def group_link
      (@activity[:transferred_group] && @activity[:action] == 'group_namespace_transfer') ||
        (@activity[:created_group] && @activity[:action] == 'group_subgroup_create')
    end

    def activity_group
      if @activity[:transferred_group].nil?
        @activity[:created_group]
      else
        @activity[:transferred_group]
      end
    end

    def activity_message # rubocop:disable Metrics/MethodLength
      if group_link
        group = activity_group

        href = link_to(
          group.puid,
          group_path(group),
          class: active_link_classes
        )

        t(
          @activity[:key],
          user: @activity[:user],
          href: href,
          old_namespace: @activity[:old_namespace],
          new_namespace: @activity[:new_namespace]
        )
      else
        t(@activity[:key], user: @activity[:user], name: @activity[:name])
      end
    end
  end
end
