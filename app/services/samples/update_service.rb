# frozen_string_literal: true

module Samples
  # Service used to Update Samples
  class UpdateService < BaseService
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      if sample.project.namespace.owners.include?(current_user)
        sample.update(params)
      else
        sample.errors.add(:base, I18n.t('services.samples.update.no_permission'))
      end
    end
  end
end
