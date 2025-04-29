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

      update_samples_count if @project.parent.type == 'Group'

      update_metadata_summary(sample)
    end

    def destroy_multiple
      samples = Sample.where(id: sample_ids).where(project_id: project.id)
      samples_deleted_puids = []

      samples = samples.destroy_all

      samples.each do |sample|
        next unless sample.deleted?

        update_metadata_summary(sample)
        samples_deleted_puids << sample.puid
      end

      deleted_samples_count = samples_deleted_puids.count
      update_samples_count(deleted_samples_count) if @project.parent.type == 'Group'

      create_activities(samples_deleted_puids) if samples_deleted_puids.size.positive?

      deleted_samples_count
    end

    def create_activities(samples_deleted_puids)
      ext_details = ExtendedDetails.create!(details: { samples_deleted_puids: })

      activity = @project.namespace.create_activity key: 'namespaces_project_namespace.samples.destroy_multiple',
                                                    owner: current_user,
                                                    parameters:
                                                    {
                                                      samples_deleted_count: samples_deleted_puids.size,
                                                      action: 'sample_destroy_multiple'
                                                    }

      activity[:extended_details_id] = ext_details.id
      activity.save
    end

    def update_metadata_summary(sample)
      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample)
    end

    def update_samples_count(deleted_samples_count = 1)
      @project.parent.update_samples_count_by_destroy_service(deleted_samples_count)
    end
  end
end
