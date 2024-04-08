# frozen_string_literal: true

# Policy for workflow execution authorization
class WorkflowExecutionPolicy < ApplicationPolicy
  def export_workflow_execution_data?
    return true if record.submitter.id == user.id

    details[:id] = record.id
    false
  end
end
