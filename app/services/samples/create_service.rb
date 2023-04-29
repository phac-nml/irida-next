# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    ProjectSampleCreateError = Class.new(StandardError)
    attr_accessor :project, :sample

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
      @sample = Sample.new(params.merge(project_id: project.id))
    end

    def execute
      authorize! @project, to: :allowed_to_modify_samples?

      sample.save
      sample
    rescue Samples::CreateService::ProjectSampleCreateError => e
      sample.errors.add(:base, e.message)
      sample
    end
  end
end
