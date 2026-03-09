# frozen_string_literal: true

module Resolvers
  module Metrics
    # Disk Usage Resolver
    class DiskUsageResolver < BaseResolver
      type String, null: false
      include ActionView::Helpers::NumberHelper

      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to only include disk usage for the projects, samples,
               and workflow executions that directly belong to this namespace. Only need to provide this argument
               if you only want to include direct projects for a group namespace,as user namespaces only have
                direct projects.',
               default_value: false

      def resolve(direct_only:)
        namespace = object.is_a?(Project) ? object.namespace : object

        number_to_human_size(calculate_disk_usage(namespace, direct_only), precision: 2, significant: false,
                                                                           strip_insignificant_zeros: false)
      end

      private

      def calculate_disk_usage(namespace, direct_only) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        ns_ids = if direct_only && !namespace.project_namespace?
                   [namespace.id] + namespace.project_namespaces.pluck(:id)
                 else
                   namespace.self_and_descendants_of_type(
                     [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
                   ).select(:id)
                 end

        blob_ids = Attachment.with(
          namespace_attachments: Attachment.where(
            attachable_type: 'Namespace',
            attachable_id: ns_ids
          ).select(:id),
          sample_attachments: Attachment.where(
            attachable_type: 'Sample',
            attachable_id: Sample.where(
              project_id: Project.where(namespace_id: ns_ids)
            )
          ).select(:id),
          sample_workflow_execution_attachments:
          Attachment.where(attachable_type: 'SamplesWorkflowExecution',
                           attachable: SamplesWorkflowExecution.joins(:workflow_execution).where(
                             workflow_execution: {
                               namespace_id: ns_ids
                             }
                           )).select(:id)
        ).where(
          Arel.sql(
            'attachments.id in (select id from namespace_attachments)
          OR attachments.id in (select id from sample_attachments)
          OR attachments.id in (select id from sample_workflow_execution_attachments)'
          )
        ).joins(file_attachment: :blob).distinct.pluck('active_storage_blobs.id')

        return 0 if blob_ids.empty?

        ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
      end
    end
  end
end
