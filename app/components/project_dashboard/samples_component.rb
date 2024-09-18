# frozen_string_literal: true

module ProjectDashboard
  # Component for rendering an activity list item
  class SamplesComponent < Component
    attr_accessor :samples, :project

    def initialize(samples: nil, project:)
      @samples = samples
      @project = project
    end
  end
end
