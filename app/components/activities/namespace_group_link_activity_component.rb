# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type NamespaceGroupLink
  class NamespaceGroupLinkActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end
  end
end
