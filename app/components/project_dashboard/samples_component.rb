# frozen_string_literal: true

module ProjectDashboard
  # Component for rendering samples recently updated
  class SamplesComponent < Component
    attr_accessor :samples, :project

    def initialize(project:, samples: nil)
      @samples = samples
      @project = project
    end
  end
end
