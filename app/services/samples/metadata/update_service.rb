# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService
      attr_accessor :sample, :metadata, :key

      def initialize(sample, user = nil, params = {}, metadata = {}, key = nil) # rubocop:disable Metrics/ParameterLists
        super(user, params.except(:sample, :id))
        @sample = sample
        @metadata = metadata
        @key = key
      end

      # def execute
      #   authorize! sample.project, to: :update_sample?

      #   sample.update(params)
      # end
    end
  end
end
