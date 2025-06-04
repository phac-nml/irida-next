# frozen_string_literal: true

module Groups
  module Samples
    # Service used to Delete Samples
    class DestroyService < BaseSampleDestroyService
      private

      def destroy_samples
        samples = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                           scope_options: { namespace: @namespace,
                                                            minimum_access_level: Member::AccessLevel::OWNER })
                  .where(id: @sample_ids)
        @deleted_samples_data = { project_data: {}, group_data: [] }
        samples = samples.destroy_all

        samples.each do |sample|
          next unless sample.deleted?

          update_metadata_summary(sample)
          add_deleted_sample_to_data(sample, sample.project.puid, sample.project.name)
        end

        create_activities_and_update_samples_count unless @deleted_samples_data[:project_data].empty?

        @deleted_samples_data[:group_data].count
      end

      def create_activities_and_update_samples_count # rubocop:disable Metrics/MethodLength
        total_deleted_samples_count = 0

        @deleted_samples_data[:project_data].each do |project_puid, sample_data|
          samples_deleted_count = sample_data.count

          project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)

          update_samples_count(project_namespace, samples_deleted_count) if project_namespace.parent.group_namespace?
          create_project_activity(project_namespace, @deleted_samples_data[:project_data][project_puid])

          total_deleted_samples_count += samples_deleted_count
        end

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

      def add_deleted_sample_to_data(sample, project_puid, project_name)
        if @deleted_samples_data[:project_data].key?(project_puid)
          @deleted_samples_data[:project_data][project_puid] << { sample_name: sample.name, sample_puid: sample.puid }
        else
          @deleted_samples_data[:project_data][project_puid] = [{ sample_name: sample.name, sample_puid: sample.puid }]
        end

        @deleted_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                                project_puid: project_puid, project_name: project_name }
      end
    end
  end
end
