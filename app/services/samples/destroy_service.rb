# frozen_string_literal: true

module Samples
  # Service used to Delete Samples
  class DestroyService < BaseService
    ProjectSampleDestroyError = Class.new(StandardError)
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      unless allowed_to_modify_projects_in_namespace?(@sample.project.namespace)
        raise ProjectSampleDestroyError,
              I18n.t('services.samples.destroy.no_permission')
      end

      sample.destroy
    rescue Samples::DestroyService::ProjectSampleDestroyError => e
      sample.errors.add(:base, e.message)
      false
    end
  end
end
