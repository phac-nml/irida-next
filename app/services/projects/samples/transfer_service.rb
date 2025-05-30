# frozen_string_literal: true

module Projects
  module Samples
    # Service used to Transfer Samples
    class TransferService < BaseProjectService
      TransferError = Class.new(StandardError)

      def execute(new_project_id, sample_ids, broadcast_target = nil)
        # Authorize if user can transfer samples from the current project
        authorize! @project, to: :transfer_sample?

        validate(new_project_id, sample_ids)

        # Authorize if user can transfer samples to the new project
        @new_project = Project.find_by(id: new_project_id)
        authorize! @new_project, to: :transfer_sample_into_project?

        if Member.effective_access_level(@project.namespace, current_user) == Member::AccessLevel::MAINTAINER
          validate_maintainer_sample_transfer
        end

        transfer(new_project_id, sample_ids, broadcast_target)
      rescue Samples::TransferService::TransferError => e
        @project.errors.add(:base, e.message)
        []
      end

      private

      def validate(new_project_id, sample_ids)
        raise TransferError, I18n.t('services.samples.transfer.empty_new_project_id') if new_project_id.blank?

        raise TransferError, I18n.t('services.samples.transfer.empty_sample_ids') if sample_ids.blank?

        return unless @project.id == new_project_id

        raise TransferError, I18n.t('services.samples.transfer.same_project')
      end

      def validate_maintainer_sample_transfer
        project_parent_and_ancestors = @project.namespace.parent.self_and_ancestor_ids
        new_project_parent_and_ancestors = @new_project.namespace.parent.self_and_ancestor_ids

        return if project_parent_and_ancestors.intersect?(new_project_parent_and_ancestors)

        raise TransferError,
              I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
      end

      def transfer(new_project_id, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferred_samples_ids = []
        transferred_samples_data = []
        not_found_sample_ids = []
        old_namespaces = namespaces_for_transfer(@project.namespace)
        new_namespaces = namespaces_for_transfer(@new_project.namespace)
        total_sample_count = sample_ids.count
        sample_ids.each.with_index(1) do |sample_id, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          sample = Sample.find_by!(id: sample_id, project_id: @project.id)
          sample.update!(project_id: new_project_id)
          transferred_samples_ids << sample_id
          transferred_samples_data << { sample_name: sample.name, sample_puid: sample.puid }
          @project.namespace.update_metadata_summary_by_sample_transfer(sample_id, old_namespaces, new_namespaces)
        rescue ActiveRecord::RecordNotFound
          not_found_sample_ids << sample_id
          next
        rescue ActiveRecord::RecordInvalid
          @project.errors.add(:samples, I18n.t('services.samples.transfer.sample_exists',
                                               sample_name: sample.name, sample_puid: sample.puid))
          next
        end

        unless not_found_sample_ids.empty?
          @project.errors.add(:samples,
                              I18n.t('services.samples.transfer.samples_not_found',
                                     sample_ids: not_found_sample_ids.join(', ')))
        end

        if transferred_samples_ids.count.positive?
          update_namespace_attributes(transferred_samples_ids)
          create_activities(transferred_samples_data, transferred_samples_ids.count)
        end

        transferred_samples_ids
      end

      def update_namespace_attributes(transferred_samples_ids)
        update_samples_count(transferred_samples_ids.count)
      end

      def create_activities(transferred_samples_data, transferred_samples_ids_count) # rubocop:disable Metrics/MethodLength
        ext_details = ExtendedDetail.create!(details: { transferred_samples_count: transferred_samples_ids_count,
                                                        transferred_samples_data: transferred_samples_data })

        activity = @project.namespace.create_activity key: 'namespaces_project_namespace.samples.transfer',
                                                      owner: current_user,
                                                      parameters:
                                                      {
                                                        target_project_puid: @new_project.puid,
                                                        target_project: @new_project.id,
                                                        transferred_samples_count: transferred_samples_ids_count,
                                                        action: 'sample_transfer'
                                                      }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_transfer')

        activity = @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.transferred_from',
                                                          owner: current_user,
                                                          parameters:
                                                          {
                                                            source_project_puid: @project.puid,
                                                            source_project: @project.id,
                                                            transferred_samples_count: transferred_samples_ids_count,
                                                            action: 'sample_transfer'
                                                          }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_transfer')
      end

      def update_samples_count(transferred_samples_count)
        if @project.parent.type == 'Group'
          @project.parent.update_samples_count_by_transfer_service(@new_project, transferred_samples_count)
        elsif @new_project.parent.type == 'Group'
          @new_project.parent.update_samples_count_by_addition_services(transferred_samples_count)
        end
      end

      def namespaces_for_transfer(project_namespace)
        [project_namespace] +
          project_namespace.parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      end
    end
  end
end
