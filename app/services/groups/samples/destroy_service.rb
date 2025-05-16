# frozen_string_literal: true

module Groups
  module Samples
    # Service used to Delete Samples
    class DestroyService < BaseService
      attr_accessor :sample, :sample_ids, :group

      def initialize(group, user = nil, params = {})
        super(user, params)
        @group = group
        @sample = params[:sample] if params[:sample]
        @sample_ids = params[:sample_ids] if params[:sample_ids]
      end

      def execute
        authorize! group, to: :destroy_sample?

        destroy_samples
      end

      private

      def destroy_samples
        samples = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                           scope_options: { namespace: group,
                                                            minimum_access_level: Member::AccessLevel::OWNER })
                  .where(id: sample_ids)
        @deleted_samples_data = { project_data: {}, group_data: [] }
        samples = samples.destroy_all

        samples.each do |sample|
          next unless sample.deleted?

          update_metadata_summary(sample)
          add_deleted_sample_to_data(sample, sample.project.puid)
        end

        create_activities_and_update_samples_count unless @deleted_samples_data[:project_data].empty?

        @deleted_samples_data[:group_data].count
      end

      def create_activities_and_update_samples_count # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        total_deleted_samples_count = 0

        @deleted_samples_data[:project_data].each do |project_puid, sample_data|
          samples_deleted_count = sample_data.count

          project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)

          update_samples_count(project_namespace, samples_deleted_count) if project_namespace.parent.group_namespace?

          project_ext_details = ExtendedDetail.create!(
            details: {
              deleted_samples_data: @deleted_samples_data[:project_data][project_puid],
              samples_deleted_count:
            }
          )

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

        group_ext_details = ExtendedDetail.create!(
          details: {
            deleted_samples_data: @deleted_samples_data[:group_data],
            samples_deleted_count: total_deleted_samples_count
          }
        )
        group_activity = group.create_activity key: 'group.samples.destroy',
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

      def update_samples_count(project_namespace, samples_deleted_count)
        project_namespace.parent.update_samples_count_by_destroy_service(samples_deleted_count)
      end

      def add_deleted_sample_to_data(sample, project_puid)
        if @deleted_samples_data[:project_data].key?(project_puid)
          @deleted_samples_data[:project_data][project_puid] << { sample_name: sample.name, sample_puid: sample.puid }
        else
          @deleted_samples_data[:project_data][project_puid] = [{ sample_name: sample.name, sample_puid: sample.puid }]
        end

        @deleted_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                                project_puid: project_puid }
      end
    end
  end
end
