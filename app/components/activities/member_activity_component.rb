# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Member
  class MemberActivityComponent < Component
    def initialize(activity: nil, **system_arguments)
      @activity = activity

      @system_arguments = system_arguments
    end
  end
end
