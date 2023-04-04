# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    ProjectSampleCreateError = Class.new(StandardError)
    attr_accessor :project

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
    end

    def execute
      unless allowed_to_modify_projects_in_namespace?(@project.namespace)
        raise ProjectSampleCreateError,
              I18n.t('services.samples.create.no_permission')
      end

      sample = Sample.new(params.merge(project_id: project.id))
      sample.save
      sample
    rescue Samples::CreateService::ProjectSampleCreateError => e
      project.errors.add(:base, e.message)
      false
    end
  end
end
