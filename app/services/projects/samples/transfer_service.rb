# frozen_string_literal: true

module Projects
  module Samples
    # Service used to transfer samples at the project level
    class TransferService < BaseSampleTransferService
      TransferError = Class.new(StandardError)

      def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize,Metrics/PerceivedComplexity
        transferrable_samples = filter_sample_ids(sample_ids, 'transfer').pluck(:id)

        transferred_samples_ids = []
        transferred_samples_data = []
        old_namespaces = namespaces_for_transfer(@namespace)
        new_namespaces = namespaces_for_transfer(new_project.namespace)
        total_sample_count = transferrable_samples.count

        Sample.suppressing_turbo_broadcasts do # rubocop:disable Metrics/BlockLength
          Sample.suppressing_counter_caches do # rubocop:disable Metrics/BlockLength
            metadata_payload = {}
            error_messages = []

            ApplicationRecord.transaction do
              dest_project = Project.find_by(id: new_project.id)
              samples = Sample.where(id: transferrable_samples).lock

              samples.each.with_index(1) do |sample, index|
                if sample.update(project_id: dest_project.id)
                  sample.metadata.each_key do |key|
                    if metadata_payload.key?(key)
                      metadata_payload[key] += 1
                    else
                      metadata_payload[key] = 1
                    end
                  end
                  transferred_samples_ids << sample.id
                  add_transfer_sample_to_activity_data(sample, transferred_samples_data)
                else
                  error_messages << I18n.t('services.samples.transfer.sample_exists',
                                           sample_name: sample.name, sample_puid: sample.puid)
                end
                update_progress_bar(index, total_sample_count, broadcast_target)
              end
            end

            Project.decrement_counter(:samples_count, @namespace.project.id, by: transferred_samples_ids.count) # rubocop:disable Rails/SkipsModelValidations
            Project.increment_counter(:samples_count, new_project.id, by: transferred_samples_ids.count) # rubocop:disable Rails/SkipsModelValidations

            update_metadata_summary_counts(metadata_payload, @namespace.project, old_namespaces, new_namespaces)
            @namespace.errors.add(:samples, error_messages) if error_messages.length.positive?
          end
        end

        if transferred_samples_ids.any?
          update_samples_count(@namespace.project, new_project, transferred_samples_ids.count)
          create_activities(transferred_samples_data, transferred_samples_ids.count)
        end

        broadcast_refresh_later_to_samples_table(old_namespaces, new_namespaces, @namespace.project, new_project)

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
