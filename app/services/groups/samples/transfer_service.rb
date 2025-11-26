# frozen_string_literal: true

module Groups
  module Samples
    # Service used to transfer samples from group level
    class TransferService < BaseSampleTransferService
      SampleExistsInProjectError = Class.new(StandardError)

      def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferrable_samples = filter_sample_ids(sample_ids, 'transfer')

        transferred_samples_ids = []
        transferred_samples_data = {}
        new_namespaces = namespaces_for_transfer(new_project.namespace)
        total_sample_count = transferrable_samples.count
        transferrable_samples.each.with_index(1) do |sample, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          old_project = sample.project
          old_namespaces = namespaces_for_transfer(old_project.namespace)

          if sample.project == new_project
            raise SampleExistsInProjectError,
                  I18n.t('services.samples.transfer.target_project_duplicate', sample_name: sample.name)
          end

          sample.update!(project_id: new_project.id)
          transferred_samples_ids << sample.id

          add_transfer_sample_to_activity_data(sample, old_project, new_project, transferred_samples_data)

          update_metadata_summary(sample, old_namespaces, new_namespaces)
        rescue ActiveRecord::RecordInvalid
          @namespace.errors.add(:samples, I18n.t('services.samples.transfer.sample_exists',
                                                 sample_name: sample.name, sample_puid: sample.puid))
          next
        rescue Samples::TransferService::SampleExistsInProjectError => e
          @namespace.errors.add(:samples, e.message)
          next
        end

        update_samples_count_and_create_activities(transferred_samples_data) if transferred_samples_ids.count.positive?
        transferred_samples_ids
      end

      def update_samples_count_and_create_activities(transferred_samples_data) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferred_samples_data.each do |key, data|
          old_namespace = Namespace.find_by(puid: key)
          new_namespace = Namespace.find_by(puid: data[0][:target_project_puid])

          update_samples_count(old_namespace.project, new_namespace.project, data.size)

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

        create_group_activity(transferred_samples_data) if @namespace.group_namespace?
      end

      def create_group_activity(transferred_samples_data)
        group_activity_data = transferred_samples_data.values.flatten

        ext_details = ExtendedDetail.create!(details: { transferred_samples_count: group_activity_data.size,
                                                        transferred_samples_data: group_activity_data })

        activity = @namespace.create_activity key: 'group.samples.transfer',
                                              owner: current_user,
                                              parameters:
                                           {
                                             transferred_samples_count: group_activity_data.size,
                                             action: 'group_sample_transfer'
                                           }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_sample_transfer')
      end

      def add_transfer_sample_to_activity_data(sample, old_project, new_project, transferred_samples_data)
        transferred_samples_data[old_project.puid] ||= []
        transferred_samples_data[old_project.puid] << { sample_name: sample.name, sample_puid: sample.puid,
                                                        source_project_name: old_project.name,
                                                        source_project_id: old_project.id,
                                                        source_project_puid: old_project.puid,
                                                        target_project_name: new_project.name,
                                                        target_project_id: new_project.id,
                                                        target_project_puid: new_project.puid }
      end
    end
  end
end
