# frozen_string_literal: true

module Samples
  # Service used to Update Samples
  class UpdateService < BaseService
    ProjectSampleUpdateError = Class.new(StandardError)
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      unless allowed_to_modify_projects_in_namespace?(sample.project.namespace)
        raise ProjectSampleUpdateError,
              I18n.t('services.samples.update.no_permission')
      end

      sample.update(params)
    rescue Samples::UpdateService::ProjectSampleUpdateError => e
      sample.errors.add(:base, e.message)
      false
    end
  end
end
