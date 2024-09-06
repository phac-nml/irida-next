# frozen_string_literal: true

# Component to render activity
class ActivityComponent < Component
  attr_accessor :activities, :pagy

  def initialize(activities:, pagy:, **system_arguments)
    @activities = activities
    @pagy = pagy
    @system_arguments = system_arguments
  end
end
