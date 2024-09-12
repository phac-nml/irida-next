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
      sample_destroyed = sample.destroy

      if sample_destroyed
        @project.namespace.create_activity key: 'namespaces_project_namespace.samples.destroy',
                                           owner: current_user,
                                           parameters:
                                            {
                                              sample_puid: sample.puid,
                                              action: 'sample_destroy'
                                            }
      end

      update_metadata_summary(sample)
    end

    def destroy_multiple # rubocop:disable Metrics/MethodLength
      samples = Sample.where(id: sample_ids).where(project_id: project.id)
      samples_to_delete_count = samples.count
      samples_deleted_puids = []

      samples = samples.destroy_all

      samples.each do |sample|
        update_metadata_summary(sample)
        samples_deleted_puids << sample.puid
      end

      @project.namespace.create_activity key: 'namespaces_project_namespace.samples.destroy_multiple',
                                         owner: current_user,
                                         parameters:
                                         {
                                           deleted_count: samples_to_delete_count,
                                           samples_deleted_puids:,
                                           action: 'sample_destroy_multiple'
                                         }

      samples_to_delete_count
    end

    def update_metadata_summary(sample)
      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample) if sample.deleted?
    end
  end
end
