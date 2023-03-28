# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      @sample = Sample.new(params)
      @sample.save

      @sample
    end
  end
end
