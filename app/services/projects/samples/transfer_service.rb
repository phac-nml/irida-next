# frozen_string_literal: true

module Projects
  module Samples
    # Service used to transfer samples at the project level
    class TransferService < BaseSampleTransferService
      TransferError = Class.new(StandardError)

      def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferrable_samples = filter_sample_ids(sample_ids, 'transfer')

        transferred_samples_ids = []
        transferred_samples_data = []
        old_namespaces = namespaces_for_transfer(@namespace)
        new_namespaces = namespaces_for_transfer(new_project.namespace)
        total_sample_count = transferrable_samples.count
        transferrable_samples.each.with_index(1) do |sample, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          sample.update!(project_id: new_project.id)
          transferred_samples_ids << sample.id
          add_transfer_sample_to_activity_data(sample, transferred_samples_data)
          update_metadata_summary(sample, @namespace.project, old_namespaces, new_namespaces)
          # @namespace.update_metadata_summary_by_sample_transfer(sample.id, old_namespaces, new_namespaces)
        rescue ActiveRecord::RecordInvalid
          @namespace.errors.add(:samples, I18n.t('services.samples.transfer.sample_exists',
                                                 sample_name: sample.name, sample_puid: sample.puid))
          next
        end

        if transferred_samples_ids.count.positive?
          update_samples_count(@namespace.project, new_project, transferred_samples_ids.count)
          create_activities(transferred_samples_data, transferred_samples_ids.count)
        end

        transferred_samples_ids
      end

      def create_activities(transferred_samples_data, transferred_samples_ids_count) # rubocop:disable Metrics/MethodLength
        ext_details = ExtendedDetail.create!(details: { transferred_samples_count: transferred_samples_ids_count,
                                                        transferred_samples_data: transferred_samples_data })

        params = {
          target_project_puid: @new_project.puid,
          target_project: @new_project.id,
          transferred_samples_count: transferred_samples_ids_count,
          action: 'sample_transfer'
        }

        create_project_activity(@namespace, ext_details.id,
                                'namespaces_project_namespace.samples.transfer', params)

        params = {
          source_project_puid: @namespace.project.puid,
          source_project: @namespace.project.id,
          transferred_samples_count: transferred_samples_ids_count,
          action: 'sample_transfer'
        }

        create_project_activity(@new_project.namespace, ext_details.id,
                                'namespaces_project_namespace.samples.transferred_from', params)
      end

      def add_transfer_sample_to_activity_data(sample, transferred_samples_data)
        transferred_samples_data << { sample_name: sample.name, sample_puid: sample.puid }
      end
    end
  end
end
