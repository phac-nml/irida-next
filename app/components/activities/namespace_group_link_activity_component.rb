# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type NamespaceGroupLink
  class NamespaceGroupLinkActivityComponent < BaseActivityComponent
    def link_to_shared_group
      group_link_group_action_types = %w[group_link_created group_link_destroyed group_link_updated]
      group_link_group_action_types.include?(@activity[:action])
    end

    def group_link_exists
      return false if @activity[:group_link].nil?

      !@activity[:group_link].deleted?
    end

    def activity_message
      href = if group_link_exists
               active_links
             else
               styled_like_links
             end

      t(
        @activity[:key],
        user: @activity[:user],
        href: href,
        namespace_type: @activity[:namespace_type],
        name: @activity[:name]
      )
    end

    private

    def active_links # rubocop:disable Metrics/MethodLength
      if link_to_shared_group
        link_to(
          @activity[:namespace_puid],
          group_path(@activity[:group_link].namespace),
          class: active_link_classes,
          title:
            t(
              'components.activity.groups.link_descriptive_text',
              group_puid: @activity[:namespace_puid]
            )
        )
      else
        link_to(
          @activity[:group_puid],
          group_path(@activity[:group_link].group),
          class: active_link_classes,
          title:
            t(
              'components.activity.groups.link_descriptive_text',
              group_puid: @activity[:group_puid]
            )
        )
      end
    end

    def styled_like_links
      return highlighted_text(@activity[:namespace_puid]) if link_to_shared_group

      highlighted_text(@activity[:group_puid])
    end
  end
end
