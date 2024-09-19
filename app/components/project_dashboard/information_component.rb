# frozen_string_literal: true

module ProjectDashboard
  # Component for rendering an project information
  class InformationComponent < Component
    attr_accessor :project

    def initialize(project:)
      @project = project
    end
  end
end
