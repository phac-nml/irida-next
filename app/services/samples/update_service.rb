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
      action_allowed_for_user(sample.project, :allowed_to_modify_samples?)

      sample.update(params)
    rescue Samples::UpdateService::ProjectSampleUpdateError => e
      sample.errors.add(:base, e.message)
      false
    end
  end
end
