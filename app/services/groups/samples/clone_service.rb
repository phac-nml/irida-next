# frozen_string_literal: true

module Groups
  module Samples
    # Service used to clone samples
    class CloneService < BaseGroupService
      CloneError = Class.new(StandardError)

      def execute(new_project_id, sample_ids, broadcast_target = nil)
        authorize! @group, to: :clone_sample?
        validate(new_project_id, sample_ids)
        @new_project = Project.find_by(id: new_project_id)
        authorize! @new_project, to: :clone_sample_into_project?
        clone_samples(sample_ids, broadcast_target)
      rescue Groups::Samples::CloneService::CloneError => e
        @group.errors.add(:base, e.message)
        {}
      end

      private

      def validate(new_project_id, sample_ids)
        raise CloneError, I18n.t('services.samples.clone.empty_new_project_id') if new_project_id.blank?

        raise CloneError, I18n.t('services.samples.clone.empty_sample_ids') if sample_ids.blank?
      end

      def clone_samples(sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @cloned_samples_data = { project_data: {}, group_data: [] }
        cloned_sample_ids = {}
        not_found_sample_ids = []
        total_sample_count = sample_ids.count
        sample_ids.each.with_index(1) do |sample_id, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          sample = Sample.find(sample_id)
          cloned_sample = clone_sample(sample)
          unless cloned_sample.nil?
            cloned_sample_ids[sample_id] = cloned_sample.id
            old_project_puid = sample.project.puid
            if @cloned_samples_data[:project_data].key?(old_project_puid)
              @cloned_samples_data[:project_data][old_project_puid] << { sample_name: sample.name,
                                                                         sample_puid: sample.puid,
                                                                         clone_puid: cloned_sample.puid }
            else
              @cloned_samples_data[:project_data][old_project_puid] = [{ sample_name: sample.name,
                                                                         sample_puid: sample.puid,
                                                                         clone_puid: cloned_sample.puid }]
            end
            @cloned_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                                   clone_puid: cloned_sample.puid, project_name: sample.project.name,
                                                   project_puid: old_project_puid }
          end
        rescue ActiveRecord::RecordNotFound
          not_found_sample_ids << sample_id
          next
        end

        unless not_found_sample_ids.empty?
          @group.errors.add(:samples,
                            I18n.t('services.samples.clone.samples_not_found',
                                   sample_ids: not_found_sample_ids.join(', ')))
        end
        return if @cloned_samples_data[:project_data].empty?

        update_samples_count if @new_project.parent.group_namespace?
        create_activities

        cloned_sample_ids
      end

      def clone_sample(sample)
        clone = sample.dup
        clone.project_id = @new_project.id
        clone.generate_puid
        clone.save!

        # update new project metadata summary and then clone attachments to the sample
        @new_project.namespace.update_metadata_summary_by_sample_addition(sample)
        clone_attachments(sample, clone)

        clone
      rescue ActiveRecord::RecordInvalid
        @group.errors.add(:samples, I18n.t('services.samples.clone.sample_exists', sample_name: sample.name,
                                                                                   sample_puid: sample.puid))
        nil
      end

      def clone_attachments(sample, clone)
        files = sample.attachments.map { |attachment| attachment.file.blob }
        ::Attachments::CreateService.new(current_user, clone, { files:, include_activity: false }).execute
      end

      def update_samples_count
        @new_project.parent.update_samples_count_by_addition_services(@cloned_samples_data[:group_data].count)
      end

      def create_activities
        create_project_level_activities
        create_group_level_activity
      end

      def create_project_level_activities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        @cloned_samples_data[:project_data].each do |project_puid, samples_data|
          old_project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)
          cloned_samples_count = samples_data.count

          ext_details = ExtendedDetail.create!(details: { cloned_samples_count:,
                                                          cloned_samples_data: samples_data })

          activity = old_project_namespace.create_activity key: 'namespaces_project_namespace.samples.clone',
                                                           owner: current_user,
                                                           parameters:
                                                        {
                                                          target_project_puid: @new_project.puid,
                                                          target_project: @new_project.id,
                                                          cloned_samples_count:,
                                                          action: 'sample_clone'
                                                        }

          activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')

          activity = @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.cloned_from',
                                                            owner: current_user,
                                                            parameters:
                                                            {
                                                              source_project_puid: old_project_namespace.puid,
                                                              source_project: old_project_namespace.project.id,
                                                              cloned_samples_count:,
                                                              action: 'sample_clone'
                                                            }

          activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')
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
                                            target_project_puid: @new_project.puid,
                                            target_project: @new_project.id,
                                            cloned_samples_count:,
                                            action: 'group_sample_clone'
                                          }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_sample_clone')
      end
    end
  end
end
