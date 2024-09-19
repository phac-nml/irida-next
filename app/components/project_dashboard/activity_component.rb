# frozen_string_literal: true

module ProjectDashboard
  # Component for rendering latest activity
  class ActivityComponent < Component
    attr_accessor :activities

    def initialize(activities: nil)
      @activities = activities
    end
  end
end
