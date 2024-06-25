# frozen_string_literal: true

module Samples
  # Service used to Delete Samples
  class DestroyService < BaseService
    attr_accessor :sample, :sample_ids, :project

    def initialize(project, user = nil, params = {})
      super(user, params)
      @project = project
      @sample = params[:sample] if params[:sample]
      @sample_ids = params[:sample_ids] if params[:sample_ids]
    end

    def execute
      authorize! project, to: :destroy_sample?

      sample.nil? ? destroy_multiple : destroy_single
    end

    private

    def destroy_single
      sample.destroy

      update_metadata_summary(sample)
    end

    def destroy_multiple
      samples = Sample.where(id: sample_ids).where(project_id: project.id)
      samples_to_delete_count = samples.count

      samples = samples.destroy_all

      samples.each do |sample|
        update_metadata_summary(sample)
      end

      samples_to_delete_count
    end

    def update_metadata_summary(sample)
      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample) if sample.deleted?
    end
  end
end
