# frozen_string_literal: true

# Component to render activity
class ActivityComponent < Component
  attr_accessor :activities, :pagy

  def initialize(activities:, pagy:)
    @activities = activities
    @pagy = pagy
  end
end
