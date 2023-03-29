# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    attr_accessor :project

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
    end

    def execute
      @sample = Sample.new(params.merge(project_id: project.id))
      @sample.save

      @sample
    end
  end
end
