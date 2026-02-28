# frozen_string_literal: true

module Resolvers
  module Metrics
    # Disk Usage Resolver
    class DiskUsageResolver < BaseResolver
      type String, null: false
      include ActionView::Helpers::NumberHelper

      def resolve # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        namespace = object.is_a?(Project) ? object.namespace : object

        number_to_human_size(Attachment.with(
          namespace_attachments: Attachment.where(
            attachable_type: 'Namespace',
            attachable_id: namespace.self_and_descendants_of_type([Group.sti_name, Namespaces::ProjectNamespace.sti_name]).select(:id)
          ).select(:id),
          sample_attachments: Attachment.where(
            attachable_type: 'Sample',
            attachable_id: Sample.where(
              project_id: Project.where(namespace_id: namespace.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).select(:id))
            )
          ).select(:id),
          sample_workflow_execution_attachments:
          Attachment.where(attachable_type: 'SamplesWorkflowExecution',
                           attachable: SamplesWorkflowExecution.joins(:workflow_execution).where(
                             workflow_execution: {
                               namespace_id: namespace.self_and_descendants_of_type(
                                 [Group.sti_name,
                                  Namespaces::ProjectNamespace.sti_name]
                               ).select(:id)
                             }
                           ))
        ).where(
          Arel.sql(
            'attachments.id in (select id from namespace_attachments)
          OR attachments.id in (select id from sample_attachments)
          OR attachments.id in (select id from sample_workflow_execution_attachments)'
          )
        ).joins(file_attachment: :blob)
                  .select('DISTINCT active_storage_blobs.byte_size')
                  .sum('CAST(active_storage_blobs.byte_size AS BIGINT)'),
                             precision: 2, significant: false, strip_insignificant_zeros: false)
      end
    end
  end
end
