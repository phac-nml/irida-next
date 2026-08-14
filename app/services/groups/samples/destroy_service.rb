# frozen_string_literal: true

module Groups
  module Samples
    # Service used to Delete Samples
    class DestroyService < BaseSampleDestroyService
      private

      def destroy_samples # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        samples = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                           scope_options: { namespace: @namespace,
                                                            minimum_access_level: Member::AccessLevel::OWNER })
                  .where(id: @sample_ids)
        @deleted_samples_data = { project_data: {}, group_data: [] }
        deleted_sample_ids = []
        samples = samples.destroy_all

        samples.each do |sample|
          next unless sample.deleted?

          deleted_sample_ids << sample.id
          update_metadata_summary(sample)
          add_deleted_sample_to_data(sample, sample.project.puid, sample.project.name)
        end

        if deleted_sample_ids.any?
          Sample.only_deleted.where(id: deleted_sample_ids).update_all(deletion_reason: params[:reason]) # rubocop:disable Rails/SkipsModelValidations
        end

        create_activities_and_update_samples_count unless @deleted_samples_data[:project_data].empty?

        @deleted_samples_data[:group_data].count
      end

      def create_activities_and_update_samples_count
        total_deleted_samples_count = 0

        @deleted_samples_data[:project_data].each do |project_puid, sample_data|
          samples_deleted_count = sample_data.count

          project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)

          create_project_activity(project_namespace, @deleted_samples_data[:project_data][project_puid])

          total_deleted_samples_count += samples_deleted_count
        end

        create_group_activity(total_deleted_samples_count)
      end

      def create_group_activity(total_deleted_samples_count) # rubocop:disable Metrics/MethodLength
        details = {
          deleted_samples_data: @deleted_samples_data[:group_data],
          samples_deleted_count: total_deleted_samples_count
        }
        activity_params = { samples_deleted_count: total_deleted_samples_count, action: 'group_samples_destroy' }
        group_ext_details = ExtendedDetail.create!(details: details)
        key = if params[:reason].present?
                activity_params[:reason] = params[:reason]
                'group.samples.destroy_with_reason'
              else
                'group.samples.destroy'
              end
        group_activity = @namespace.create_activity key: key,
                                                    owner: current_user,
                                                    parameters: activity_params
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
