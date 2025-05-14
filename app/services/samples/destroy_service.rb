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

    def destroy_multiple
      samples = query_samples
      samples_deleted_puids = []
      @deleted_samples_data = { project_data: {}, group_data: [] }
      samples = samples.destroy_all

      samples.each do |sample|
        next unless sample.deleted?

        update_metadata_summary(sample)
        samples_deleted_puids << sample.puid
        add_deleted_sample_to_data(sample, sample.project.puid)
      end

      deleted_samples_count = samples_deleted_puids.count
      if @namespace.project_namespace? && @namespace.project.parent.type == 'Group'
        update_samples_count(deleted_samples_count)
      end

      create_activities unless @deleted_samples_data[:project_data].empty?

      deleted_samples_count
    end

    def create_activities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      total_deleted_samples_count = 0

      @deleted_samples_data[:project_data].each do |project_puid, sample_data|
        samples_deleted_count = sample_data.count
        project_ext_details = ExtendedDetail.create!(
          details: {
            deleted_samples_data: @deleted_samples_data[:project_data][project_puid],
            samples_deleted_count:
          }
        )

        project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)
        project_activity = project_namespace.create_activity(
          key: 'namespaces_project_namespace.samples.destroy_multiple',
          owner: current_user,
          parameters:
          {
            samples_deleted_count:,
            action: 'project_sample_destroy_multiple'
          }
        )

        project_activity.create_activity_extended_detail(extended_detail_id: project_ext_details.id,
                                                         activity_type: 'project_sample_destroy_multiple')
        total_deleted_samples_count += samples_deleted_count
      end

      return unless @namespace.group_namespace?

      group_ext_details = ExtendedDetail.create!(
        details: {
          deleted_samples_data: @deleted_samples_data[:group_data],
          samples_deleted_count: total_deleted_samples_count
        }
      )
      group_activity = @namespace.create_activity key: 'group.samples.destroy',
                                                  owner: current_user,
                                                  parameters:
                                 {
                                   samples_deleted_count: total_deleted_samples_count,
                                   action: 'group_samples_destroy'
                                 }
      group_activity.create_activity_extended_detail(extended_detail_id: group_ext_details.id,
                                                     activity_type: 'group_samples_destroy')
    end

    def update_metadata_summary(sample)
      sample.project.namespace.update_metadata_summary_by_sample_deletion(sample)
    end

    def update_samples_count(deleted_samples_count = 1)
      return unless @namespace.project_namespace?

      @namespace.project.parent.update_samples_count_by_destroy_service(deleted_samples_count)
    end

    def query_samples
      if @namespace.project_namespace?
        Sample.where(id: sample_ids).where(project_id: namespace.project.id)
      else
        authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                 scope_options: { namespace:, minimum_access_level: Member::AccessLevel::OWNER })
          .where(id: sample_ids)
      end
    end

    def add_deleted_sample_to_data(sample, project_puid)
      if @deleted_samples_data[:project_data].key?(project_puid)
        @deleted_samples_data[:project_data][project_puid] << { sample_name: sample.name, sample_puid: sample.puid }
      else
        @deleted_samples_data[:project_data][project_puid] = [{ sample_name: sample.name, sample_puid: sample.puid }]
      end

      return unless @namespace.group_namespace?

      @deleted_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                              project_puid: project_puid }
    end
  end
end
