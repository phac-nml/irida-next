# frozen_string_literal: true

module Samples
  # Service used to Delete Samples
  class DestroyService < BaseService
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      if sample.nil?
        nil
      elsif sample.project.namespace.owners.include?(current_user)
        sample.destroy
      else
        sample.errors.add(:base, I18n.t('services.samples.destroy.no_permission'))
      end
    end
  end
end
