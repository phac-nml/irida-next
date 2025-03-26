# frozen_string_literal: true

# Policy for attachments authorization
class AttachmentPolicy < ApplicationPolicy
  def read?
    case record.attachable
    when SamplesWorkflowExecution
      allowed_to?(:read?, record.attachable.workflow_execution)
    when WorkflowExecution, Group
      allowed_to?(:read?, record.attachable)
    when Namespaces::ProjectNamespace
      allowed_to?(:read?, record.attachable.project)
    else
      false
    end
  end
end
