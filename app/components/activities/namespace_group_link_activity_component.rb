# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type NamespaceGroupLink
  class NamespaceGroupLinkActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end

    def group_link_exists
      return false if @activity[:group_link].nil?

      !@activity[:group_link].deleted?
    end
  end
end
