# frozen_string_literal: true

# Policy for attachments authorization
class AttachmentPolicy < ApplicationPolicy
  def read?
    case record.attachable
    when SamplesWorkflowExecution
      allowed_to?(:preview_attachment?, record.attachable.workflow_execution)
    when WorkflowExecution, Group, Sample
      allowed_to?(:preview_attachment?, record.attachable)
    when Namespaces::ProjectNamespace
      allowed_to?(:preview_attachment?, record.attachable.project)
    else
      false
    end
  end

  # This scope gets all the attachments that belong to a namespace which can include descendants via the
  # passed in namespace_ids. The attachments include those attached to samples, workflow executions,
  # and projects within that namespace
  scope_for :relation, :namespace_attachments do |relation, options| # rubocop:disable Metrics/BlockLength
    ns_ids = options[:namespace_ids]

    return relation.none if ns_ids.empty?

    relation.with(
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
      Attachment.where(
        attachable_type: 'SamplesWorkflowExecution',
        attachable_id: SamplesWorkflowExecution.joins(:workflow_execution).where(
          workflow_execution: {
            namespace_id: ns_ids
          }
        ).select(:id)
      ).select(:id),
      workflow_execution_attachments: Attachment.where(
        attachable_type: 'WorkflowExecution',
        attachable: WorkflowExecution.where(namespace_id: ns_ids)
      ).select(:id)
    ).where(
      Arel.sql(
        'attachments.id in (select id from namespace_attachments)
          OR attachments.id in (select id from sample_attachments)
          OR attachments.id in (select id from sample_workflow_execution_attachments)
          OR attachments.id in (select id from workflow_execution_attachments)'
      )
    )
  end
end
