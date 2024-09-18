# frozen_string_literal: true

module ProjectDashboard
  # Component for rendering an activity list item
  class ActivityComponent < Component
    attr_accessor :activities

    def initialize(activities: nil)
      @activities = activities
    end
  end
end
