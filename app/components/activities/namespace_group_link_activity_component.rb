# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type NamespaceGroupLink
  class NamespaceGroupLinkActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end

    def link_to_shared_group
      group_link_group_action_types = %w[group_link_created group_link_destroyed group_link_updated]
      group_link_group_action_types.include?(@activity[:action])
    end

    def group_link_exists
      return false if @activity[:group_link].nil?

      !@activity[:group_link].deleted?
    end
  end
end
