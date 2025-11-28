# frozen_string_literal: true

module Projects
  module Samples
    # Service used to transfer samples at the project level
    class TransferService < BaseSampleTransferService
      TransferError = Class.new(StandardError)

      def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        transferrable_samples = filter_sample_ids(sample_ids, 'transfer')
        sample_ids_to_transfer = transferrable_samples.pluck(:id)

        update_progress_bar(5, 100, broadcast_target)

        Sample.where(id: sample_ids_to_transfer).where.not(
          id: Sample.joins('left join "samples" as "conflicting_samples" on "samples"."name" = "conflicting_samples"."name"')
                    .where(Arel.sql("\"conflicting_samples\".\"project_id\" = '#{new_project.id}' AND \"conflicting_samples\".\"deleted_at\" IS NULL"))
                    .where(id: transferrable_samples.pluck(:id))
        ).update_all(project_id: new_project.id) # rubocop:disable Rails/SkipsModelValidations

        update_progress_bar(95, 100, broadcast_target)

        transferred_samples_ids = Sample.where(id: sample_ids_to_transfer, project_id: new_project.id).pluck(:id)
        transferred_samples_data = Sample.where(id: transferred_samples_ids).pluck(:name, :puid).map do |name, puid|
          { sample_name: name, sample_puid: puid }
        end

        # non transferrable samples due to name conflicts
        error_messages = Sample.where(id: sample_ids_to_transfer).where.not(project_id: new_project.id).pluck(:name,
                                                                                                              :puid).map do |name, puid|
          I18n.t('services.samples.transfer.sample_exists',
                 sample_name: name, sample_puid: puid)
        end
        @namespace.errors.add(:samples, error_messages) if error_messages.any?

        return [] if transferred_samples_ids.empty?

        metadata_payload = {}
        Sample.select(
          Arel::Nodes::NamedFunction.new('JSONB_OBJECT_KEYS', [Sample.arel_table[:metadata]]).as('key'),
          Arel.star.count
        ).where(id: transferred_samples_ids).group(Arel::Nodes::SqlLiteral.new('key')).each do |sample|
          metadata_payload[sample.key] = sample.count
        end

        old_namespaces = namespaces_for_transfer(@namespace)
        new_namespaces = namespaces_for_transfer(new_project.namespace)

        update_metadata_summary_counts(metadata_payload, @namespace.project, old_namespaces, new_namespaces)

        Project.decrement_counter(:samples_count, @namespace.project.id, by: transferred_samples_ids.count) # rubocop:disable Rails/SkipsModelValidations
        Project.increment_counter(:samples_count, new_project.id, by: transferred_samples_ids.count) # rubocop:disable Rails/SkipsModelValidations

        update_samples_count(@namespace.project, new_project, transferred_samples_ids.count)
        create_activities(transferred_samples_data, transferred_samples_ids.count)

        update_progress_bar(100, 100, broadcast_target)

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
