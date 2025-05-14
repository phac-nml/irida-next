# frozen_string_literal: true

module Samples
  # Service used to Delete Samples
  class DestroyService < BaseService
    attr_accessor :sample, :sample_ids, :namespace

    def initialize(namespace, user = nil, params = {})
      super(user, params)
      @namespace = namespace
      @sample = params[:sample] if params[:sample]
      @sample_ids = params[:sample_ids] if params[:sample_ids]
    end

    def execute
      if @namespace.project_namespace?
        authorize! namespace.project, to: :destroy_sample?
      else
        authorize! namespace, to: :destroy_sample?
      end

      sample.nil? ? destroy_multiple : destroy_single
    end

    private

    def destroy_single
      sample_destroyed = sample.destroy

      if sample_destroyed
        @namespace.project.namespace.create_activity key: 'namespaces_project_namespace.samples.destroy',
                                                     owner: current_user,
                                                     parameters:
                                            {
                                              sample_puid: sample.puid,
                                              action: 'sample_destroy'
                                            }
      end

      update_samples_count if @namespace.project_namespace? && @namespace.project.parent.type == 'Group'

      update_metadata_summary(sample)
    end

    def destroy_multiple # rubocop:disable Metrics/AbcSize
      samples = if @namespace.project_namespace?
                  Sample.where(id: sample_ids).where(project_id: namespace.project.id)
                else
                  nil
                end
      samples_deleted_puids = []
      deleted_samples_data = []
      samples = samples.destroy_all

      samples.each do |sample|
        next unless sample.deleted?

        update_metadata_summary(sample)
        samples_deleted_puids << sample.puid
        deleted_samples_data << { sample_name: sample.name, sample_puid: sample.puid }
      end

      deleted_samples_count = samples_deleted_puids.count
      if @namespace.project_namespace? && @namespace.project.parent.type == 'Group'
        update_samples_count(deleted_samples_count)
      end

      create_activities(deleted_samples_data) if deleted_samples_data.size.positive?

      deleted_samples_count
    end

    def create_activities(deleted_samples_data)
      ext_details = ExtendedDetail.create!(details: { samples_deleted_count: deleted_samples_data.size,
                                                      deleted_samples_data: deleted_samples_data })

      activity = @namespace.project.namespace.create_activity key: 'namespaces_project_namespace.samples.destroy_multiple',
                                                              owner: current_user,
                                                              parameters:
                                                    {
                                                      samples_deleted_count: deleted_samples_data.size,
                                                      action: 'sample_destroy_multiple'
                                                    }

      activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                               activity_type: 'sample_destroy_multiple')
    end

    def update_metadata_summary(sample)
      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample)
    end

    def update_samples_count(deleted_samples_count = 1)
      return unless @namespace.project_namespace?

      @namespace.project.parent.update_samples_count_by_destroy_service(deleted_samples_count)
    end
  end
end
