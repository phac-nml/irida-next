# frozen_string_literal: true

# Component to render activity
class ActivityComponent < Component
  attr_accessor :activities

  def initialize(activities:, **system_arguments)
    @activities = activities
    @system_arguments = system_arguments
  end
end
