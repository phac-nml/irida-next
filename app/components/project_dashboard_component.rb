# frozen_string_literal: true

# Component for rendering project details dashboard
class ProjectDashboardComponent < Component
  def initialize(activities:, samples:, project:)
    @activities = activities
    @samples = samples
    @project = project
  end
end
