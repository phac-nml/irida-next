# frozen_string_literal: true

module Samples
  # Service used to Delete Multiple Samples
  class MultipleDestroyService < BaseService
    attr_accessor :project, :sample_ids

    def initialize(project, sample_ids, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @project = project
      @sample_ids = sample_ids
    end

    def execute
      authorize! @project, to: :destroy_sample?

      samples = Sample.where(id: @sample_ids).where(project_id: @project.id)
      samples_to_delete_count = samples.count

      samples.each do |sample|
        sample.project.namespace.update_metadata_summary_by_sample_deletion(sample) if sample.deleted?
      end

      samples.destroy_all
      samples_to_delete_count
    end
  end
end
