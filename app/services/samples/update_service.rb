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
      authorize! sample.project, to: :update_sample?

      sample.update(params)
    end
  end
end
