# frozen_string_literal: true

module Groups
  module Samples
    # Service used to transfer samples from group level
    class TransferService < BaseGroupService # rubocop:disable Metrics/ClassLength
      TransferError = Class.new(StandardError)
      SampleExistsInProjectError = Class.new(StandardError)

      def execute(new_project_id, sample_ids, broadcast_target = nil)
        # Authorize if user can transfer samples from the current project
        authorize! @group, to: :transfer_sample?

        validate(new_project_id, sample_ids)

        # Authorize if user can transfer samples to the new project
        @new_project = Project.find_by(id: new_project_id)
        authorize! @new_project, to: :transfer_sample_into_project?

        if Member.effective_access_level(@group, current_user) == Member::AccessLevel::MAINTAINER
          validate_maintainer_sample_transfer
        end

        transfer(@new_project, sample_ids, broadcast_target)
      rescue Samples::TransferService::TransferError => e
        @group.errors.add(:base, e.message)
        []
      end

      private

      def validate(new_project_id, sample_ids)
        raise TransferError, I18n.t('services.groups.samples.transfer.empty_new_project_id') if new_project_id.blank?

        raise TransferError, I18n.t('services.groups.samples.transfer.empty_sample_ids') if sample_ids.blank?
      end

      def validate_maintainer_sample_transfer
        project_parent_and_ancestors = @group.self_and_ancestor_ids
        new_project_parent_and_ancestors = @new_project.namespace.parent.self_and_ancestor_ids

        return if project_parent_and_ancestors.intersect?(new_project_parent_and_ancestors)

        raise TransferError,
              I18n.t('services.groups.samples.transfer.maintainer_transfer_not_allowed')
      end

      def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferred_samples_ids = []
        not_found_sample_ids = []
        transferred_samples_data = {}
        new_namespaces = namespaces_for_transfer(new_project.namespace)
        total_sample_count = sample_ids.count
        sample_ids.each.with_index(1) do |sample_id, index| # rubocop:disable Metrics/BlockLength
          update_progress_bar(index, total_sample_count, broadcast_target)
          sample = Sample.find(sample_id)
          old_project = sample.project
          old_namespaces = namespaces_for_transfer(old_project.namespace)

          if sample.project == new_project
            raise SampleExistsInProjectError,
                  I18n.t('services.groups.samples.transfer.target_project_duplicate', sample_name: sample.name)
          end

          sample.update!(project_id: new_project.id)
          transferred_samples_ids << sample_id

          transferred_samples_data[old_project.puid] ||= []
          transferred_samples_data[old_project.puid] << { sample_name: sample.name, sample_puid: sample.puid,
                                                          source_project_name: old_project.name,
                                                          source_project_id: old_project.id,
                                                          source_project_puid: old_project.puid,
                                                          target_project_name: new_project.name,
                                                          target_project_id: new_project.id,
                                                          target_project_puid: new_project.puid }

          old_project.namespace.update_metadata_summary_by_sample_transfer(sample_id,
                                                                           old_namespaces, new_namespaces)
        rescue ActiveRecord::RecordNotFound
          not_found_sample_ids << sample_id
          next
        rescue ActiveRecord::RecordInvalid
          @group.errors.add(:samples, I18n.t('services.groups.samples.transfer.sample_exists',
                                             sample_name: sample.name, sample_puid: sample.puid))
          next
        rescue Samples::TransferService::SampleExistsInProjectError => e
          @group.errors.add(:samples, e.message)
          next
        end

        unless not_found_sample_ids.empty?
          @group.errors.add(:samples,
                            I18n.t('services.groups.samples.transfer.samples_not_found',
                                   sample_ids: not_found_sample_ids.join(', ')))
        end

        if transferred_samples_ids.count.positive?
          update_namespace_attributes(new_project, transferred_samples_ids)
          create_activities(transferred_samples_data)
        end

        transferred_samples_ids
      end

      def update_namespace_attributes(new_project, transferred_samples_ids)
        update_samples_count(new_project, transferred_samples_ids.count)
      end

      def create_activities(transferred_samples_data) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferred_samples_data.each do |key, data|
          old_namespace = Namespace.find_by(puid: key)
          new_namespace = Namespace.find_by(puid: data[0][:target_project_puid])

          ext_details = ExtendedDetail.create!(details: { transferred_samples_count: data.size,
                                                          transferred_samples_data: data })

          params = {
            target_project_puid: data[0][:target_project_puid],
            target_project: data[0][:target_project_id],
            transferred_samples_count: data.size,
            action: 'sample_transfer'
          }

          create_project_activity(old_namespace, ext_details.id, 'namespaces_project_namespace.samples.transfer',
                                  params)

          params = {
            source_project_puid: data[0][:source_project_puid],
            source_project: data[0][:source_project_id],
            transferred_samples_count: data.size,
            action: 'sample_transfer'
          }

          create_project_activity(new_namespace, ext_details.id,
                                  'namespaces_project_namespace.samples.transferred_from', params)
        end

        create_group_activity(transferred_samples_data)
      end

      def create_group_activity(transferred_samples_data)
        group_activity_data = transferred_samples_data.values.flatten

        ext_details = ExtendedDetail.create!(details: { transferred_samples_count: group_activity_data.size,
                                                        transferred_samples_data: group_activity_data })

        activity = @group.create_activity key: 'group.samples.transfer',
                                          owner: current_user,
                                          parameters:
                                           {
                                             transferred_samples_count: group_activity_data.size,
                                             action: 'group_sample_transfer'
                                           }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_sample_transfer')
      end

      def create_project_activity(namespace, ext_details_id, key, params)
        activity = namespace.create_activity key: key,
                                             owner: current_user,
                                             parameters: params

        activity.create_activity_extended_detail(extended_detail_id: ext_details_id,
                                                 activity_type: 'sample_transfer')
      end

      def update_samples_count(new_project, transferred_samples_count)
        return unless new_project.parent.type == 'Group'

        new_project.parent.update_samples_count_by_transfer_service(new_project, transferred_samples_count)
      end

      def namespaces_for_transfer(project_namespace)
        [project_namespace] +
          project_namespace.parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      end
    end
  end
end
