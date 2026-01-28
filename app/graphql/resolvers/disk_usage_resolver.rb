# frozen_string_literal: true

module Resolvers
  # Disk Usage Resolver
  class DiskUsageResolver < BaseResolver
    type Integer, null: false

    def resolve # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      namespace = object.is_a?(Project) ? object.namespace : object

      Attachment.with(
        namespace_attachments: Attachment.where(attachable_type: 'Namespace', attachable_id: namespace.id).select(:id),
        sample_attachments: Attachment.where(
          attachable_type: 'Sample',
          attachable_id: Sample.where(
            project_id: Project.where(namespace_id: namespace.self_and_descendants_of_type([Project]).select(:id))
          )
        ).select(:id),
        sample_workflow_execution_attachments:
        Attachment.where(attachable_type: 'SamplesWorkflowExecution',
                         attachable: SamplesWorkflowExecution.where(
                           workflow_execution_id: WorkflowExecution.where(
                             namespace_id: namespace.self_and_descendants_of_type([Group, Project]).select(:id)
                           )
                         ))
      ).where(
        Arel.sql(
          'attachments.id in (select id from namespace_attachments)
          OR attachments.id in (select id from sample_attachments)
          OR attachments.id in (select id from sample_workflow_execution_attachments)'
        )
      ).joins(file_attachment: :blob)
                .select('DISTINCT active_storage_blobs.byte_size')
                .sum('active_storage_blobs.byte_size')
                .to_i
    end
  end
end
