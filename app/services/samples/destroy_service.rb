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
      authorize! sample.project, to: :destroy_sample?

      sample.destroy

      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample) if sample.deleted?
    end
  end
end
