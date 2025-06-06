# frozen_string_literal: true

module Groups
  module Samples
    # Service used to clone group samples
    class CloneService < BaseGroupService
      CloneError = Class.new(StandardError)

      private

      def clone_samples(sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @cloned_samples_data = { project_data: {}, group_data: [] }
        cloned_sample_ids = {}
        filtered_samples = filter_sample_ids(sample_ids, 'clone', Member::AccessLevel::MAINTAINER)
        total_sample_count = filtered_samples.count
        filtered_samples.each.with_index(1) do |sample, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          cloned_sample = clone_sample(sample)
          unless cloned_sample.nil?
            cloned_sample_ids[sample.id] = cloned_sample.id
            old_project_puid = sample.project.puid
            add_cloned_sample_data(sample, cloned_sample.puid, old_project_puid)
          end
        end

        unless @cloned_samples_data[:project_data].empty?
          update_samples_count(cloned_sample_ids.count) if @new_project.parent.group_namespace?
          create_activities
        end

        cloned_sample_ids
      end

      def add_cloned_sample_data(sample, cloned_puid, old_project_puid)
        if @cloned_samples_data[:project_data].key?(old_project_puid)
          @cloned_samples_data[:project_data][old_project_puid] << { sample_name: sample.name,
                                                                     sample_puid: sample.puid,
                                                                     clone_puid: cloned_puid }
        else
          @cloned_samples_data[:project_data][old_project_puid] = [{ sample_name: sample.name,
                                                                     sample_puid: sample.puid,
                                                                     clone_puid: cloned_puid }]
        end
        @cloned_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                               clone_puid: cloned_puid, source_project_name: sample.project.name,
                                               source_project_puid: old_project_puid,
                                               target_project_name: @new_project.name,
                                               target_project_puid: @new_project.puid }
      end

      def create_activities
        create_project_level_activities
        create_group_level_activity
      end

      def create_project_level_activities
        @cloned_samples_data[:project_data].each do |project_puid, samples_data|
          old_project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)

          create_project_level_activity(samples_data, old_project_namespace)
        end
      end

      def create_group_level_activity
        cloned_samples_count = @cloned_samples_data[:group_data].count
        ext_details = ExtendedDetail.create!(details: { cloned_samples_count:,
                                                        cloned_samples_data: @cloned_samples_data[:group_data] })

        activity = @group.create_activity key: 'group.samples.clone',
                                          owner: current_user,
                                          parameters:
                                          {
                                            cloned_samples_count:,
                                            action: 'group_sample_clone'
                                          }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_sample_clone')
      end
    end
  end
end
